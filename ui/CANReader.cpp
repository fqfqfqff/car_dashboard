#include "CANReader.h"
#include "backend/DataModel.h"

#include <QDebug>
#include <QMutexLocker>

// ─── Kvaser CANlib ─────────────────────────────────────────────────────────────
#ifdef Q_OS_WIN
#  include <canlib.h>
#else
#  define canOPEN_ACCEPT_VIRTUAL 0x0020
typedef int canHandle;
static int  canInitializeLibrary()                              { return 0; }
static int  canOpenChannel(int, int)                            { return -1; }
static int  canSetBusParams(int, long, int, int, int, int, int) { return -1; }
static int  canBusOn(int)                                       { return -1; }
static int  canBusOff(int)                                      { return 0; }
static int  canClose(int)                                       { return 0; }
static int  canRead(int, long*, void*, unsigned int*, unsigned int*, unsigned long*) { return -1; }
static const char *canGetErrorText(int, char*, int)             { return "stub"; }
static constexpr int canOK        = 0;
static constexpr int canERR_NOMSG = -2;
#endif

// ─── Флаги фреймов Kvaser ──────────────────────────────────────────────────────
// canMSG_STD      = 0x0002  — стандартный 11-bit ID
// canMSG_RTR      = 0x0010  — Remote Transmission Request
// canMSG_ERROR_FRAME = 0x0020 — error frame (игнорируем)
// canMSG_TXACK    = 0x0040  — TX подтверждение (игнорируем — это эхо нашей отправки)
// canMSG_TXRQ     = 0x0080  — TX request (игнорируем)
static constexpr unsigned int SKIP_FLAGS = 0x0040 | 0x0080 | 0x0020;
//                                         TXACK    TXRQ     ERROR_FRAME

// ═══════════════════════════════════════════════════════════════════════════════
// CANWorker
// ═══════════════════════════════════════════════════════════════════════════════

CANWorker::CANWorker(QObject *parent)
    : QObject(parent)
{
    m_timer = new QTimer(this);
    m_timer->setInterval(POLL_INTERVAL_MS);
    m_timer->setSingleShot(false);
    connect(m_timer, &QTimer::timeout, this, &CANWorker::poll);
}

CANWorker::~CANWorker()
{
    if (m_open) disconnectDevice();
}

void CANWorker::connectDevice(int channel, int bitrate)
{
    if (m_open) disconnectDevice();

    canInitializeLibrary();

    // canOPEN_ACCEPT_VIRTUAL позволяет открыть виртуальный канал
    canHandle h = canOpenChannel(channel, canOPEN_ACCEPT_VIRTUAL);
    if (h < 0) {
        char errBuf[128] = {};
        canGetErrorText(static_cast<canStatus>(h), errBuf, sizeof(errBuf));
        emit errorOccurred(QString("canOpenChannel(%1) failed: %2").arg(channel).arg(errBuf));
        return;
    }

    // ── Битрейт ───────────────────────────────────────────────────────────────
    // Для виртуальных каналов canSetBusParams может не требоваться,
    // но вызвать его нужно. Передаём сырое значение в bps —
    // виртуальный канал принимает любые параметры (игнорирует физику).
    // Для реального железа Kvaser также принимает сырой bps начиная с CANlib 5.x.
    canStatus stat = canSetBusParams(h, static_cast<long>(bitrate), 0, 0, 0, 0, 0);
    if (stat != canOK) {
        // Виртуальный канал иногда возвращает canERR_PARAM — игнорируем,
        // это не критично для приёма фреймов.
        char errBuf[128] = {};
        canGetErrorText(stat, errBuf, sizeof(errBuf));
        qWarning() << "[CANWorker] canSetBusParams warning (non-fatal):" << errBuf;
        // НЕ возвращаемся — продолжаем подключение
    }

    stat = canBusOn(h);
    if (stat != canOK) {
        char errBuf[128] = {};
        canGetErrorText(stat, errBuf, sizeof(errBuf));
        canClose(h);
        emit errorOccurred(QString("canBusOn failed: %1").arg(errBuf));
        return;
    }

    m_handle = h;
    m_open   = true;
    m_timer->start();
    emit connected();
    qDebug() << "[CANWorker] Connected to channel" << channel << "at" << bitrate << "bps, handle=" << h;
}

void CANWorker::disconnectDevice()
{
    m_timer->stop();
    if (m_handle >= 0) {
        canBusOff(m_handle);
        canClose(m_handle);
        m_handle = -1;
    }
    m_open = false;
    emit disconnected();
    qDebug() << "[CANWorker] Disconnected";
}

void CANWorker::poll()
{
    if (!m_open || m_handle < 0) return;

    int received = 0;
    for (int i = 0; i < FRAMES_PER_POLL; ++i) {
        long         id    = 0;
        uint8_t      data[8] = {};
        unsigned int dlc   = 0;
        unsigned int flags = 0;
        unsigned long time = 0;

        int stat = canRead(m_handle, &id, data, &dlc, &flags, &time);

        if (stat == canERR_NOMSG) break;   // очередь пуста

        if (stat != canOK) continue;       // ошибка чтения — пропускаем

        // Пропускаем TX-эхо, TX-request и error frames
        if (flags & SKIP_FLAGS) continue;

        QByteArray payload(reinterpret_cast<const char*>(data),
                           static_cast<int>(dlc));
        emit frameReceived(id, payload);
        ++received;
    }

    if (received > 0) {
        qDebug() << "[CANWorker] poll: received" << received << "frames";
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CANReader
// ═══════════════════════════════════════════════════════════════════════════════

CANReader::CANReader(DataModel *model, QObject *parent)
    : QObject(parent)
    , m_model(model)
{
    m_thread = new QThread(this);
    m_worker = new CANWorker();
    m_worker->moveToThread(m_thread);

    connect(m_worker, &CANWorker::frameReceived,  this, &CANReader::onFrame,        Qt::QueuedConnection);
    connect(m_worker, &CANWorker::connected,       this, &CANReader::onConnected,    Qt::QueuedConnection);
    connect(m_worker, &CANWorker::disconnected,    this, &CANReader::onDisconnected, Qt::QueuedConnection);
    connect(m_worker, &CANWorker::errorOccurred,   this, &CANReader::onError,        Qt::QueuedConnection);

    connect(m_thread, &QThread::finished, m_worker, &QObject::deleteLater);

    m_thread->start();
    qDebug() << "[CANReader] Worker thread started";
}

CANReader::~CANReader()
{
    QMetaObject::invokeMethod(m_worker, "disconnectDevice", Qt::BlockingQueuedConnection);
    m_thread->quit();
    m_thread->wait(3000);
}

bool CANReader::isConnected() const
{
    QMutexLocker lock(&m_mutex);
    return m_connected;
}

QString CANReader::statusText() const
{
    QMutexLocker lock(&m_mutex);
    return m_statusText;
}

void CANReader::setChannel(int v)
{
    if (m_channel == v) return;
    m_channel = v;
    emit channelChanged();
}

void CANReader::setBitrate(int v)
{
    if (m_bitrate == v) return;
    m_bitrate = v;
    emit bitrateChanged();
}

void CANReader::connectDevice()
{
    setStatus(QString("Подключение к каналу %1...").arg(m_channel));
    QMetaObject::invokeMethod(m_worker, "connectDevice",
                              Qt::QueuedConnection,
                              Q_ARG(int, m_channel),
                              Q_ARG(int, m_bitrate));
}

void CANReader::disconnectDevice()
{
    QMetaObject::invokeMethod(m_worker, "disconnectDevice", Qt::QueuedConnection);
}

void CANReader::onConnected()
{
    {
        QMutexLocker lock(&m_mutex);
        m_connected = true;
    }
    setStatus(QString("CAN: канал %1, %2 kbps").arg(m_channel).arg(m_bitrate / 1000));
    if (m_model) {
        m_model->setCanConnected(true);
        m_model->setEngineRunning(true);
    }
    emit connectionChanged();
    qDebug() << "[CANReader] onConnected — canConnected=true, engineRunning=true";
}

void CANReader::onDisconnected()
{
    {
        QMutexLocker lock(&m_mutex);
        m_connected = false;
    }
    setStatus("Не подключён");
    if (m_model) {
        m_model->setCanConnected(false);
        m_model->setEngineRunning(false);
    }
    emit connectionChanged();
}

void CANReader::onError(const QString &msg)
{
    // ВАЖНО: ошибка не отключает canConnected если уже были успешно подключены.
    // Иначе симулятор перезапишет данные с CAN.
    setStatus("Ошибка: " + msg);
    {
        QMutexLocker lock(&m_mutex);
        // Не меняем m_connected — ошибка может быть временной
    }
    qWarning() << "[CANReader]" << msg;
}

void CANReader::onFrame(long id, QByteArray data)
{
    ++m_frameCount;
    emit frameCountChanged();
    decodeFrame(id, data);

    // Диагностика первых фреймов
    if (m_frameCount <= 5 || m_frameCount % 100 == 0) {
        qDebug() << "[CANReader] frame #" << m_frameCount
                 << "id=0x" << QString::number(id, 16).toUpper()
                 << "dlc=" << data.size()
                 << "data=" << data.toHex();
    }
}

// ─── Декодирование ────────────────────────────────────────────────────────────

void CANReader::decodeFrame(long id, const QByteArray &d)
{
    if (!m_model) return;

    const auto u8  = [&](int i) -> uint8_t  {
        return (i < d.size()) ? static_cast<uint8_t>(d[i]) : 0;
    };
    const auto u16 = [&](int i) -> uint16_t {
        return (static_cast<uint16_t>(u8(i)) << 8) | u8(i + 1);
    };

    switch (id) {

    case CanID::SPEED:
        // bytes 0-1: uint16 big-endian, LSB = 0.01 km/h
        m_model->setSpeed(u16(0) * 0.01);
        break;

    case CanID::RPM:
        // bytes 0-1: uint16 big-endian, LSB = 0.25 rpm
        m_model->setRpm(u16(0) * 0.25);
        break;

    case CanID::ENGINE_TEMP:
        // byte 0: uint8, value = temp + 40  → range -40..215°C
        m_model->setEngineTemp(static_cast<double>(u8(0)) - 40.0);
        break;

    case CanID::FUEL_LEVEL:
        // byte 0: uint8, 0-100%
        m_model->setFuelLevel(static_cast<double>(u8(0)));
        break;

    case CanID::STATUS_1: {
        const uint8_t b = u8(0);
        m_model->setCheckEngine( b & CanID::BIT_CHECK_ENGINE );
        m_model->setAbsActive  ( b & CanID::BIT_ABS_ACTIVE   );
        m_model->setEspActive  ( b & CanID::BIT_ESP_ACTIVE    );
        m_model->setTpmsActive ( b & CanID::BIT_TPMS          );
        m_model->setFuelLow    ( b & CanID::BIT_FUEL_LOW      );
        m_model->setSeatbelt   ( b & CanID::BIT_SEATBELT      );
        m_model->setTurnLeft   ( b & CanID::BIT_TURN_LEFT     );
        m_model->setTurnRight  ( b & CanID::BIT_TURN_RIGHT    );
        break;
    }

    case CanID::STATUS_2: {
        const uint8_t b = u8(0);
        m_model->setOilPressure (b & CanID::BIT_OIL_PRESSURE  );
        m_model->setOverheating (b & CanID::BIT_OVERHEATING    );
        m_model->setBrakeSystem (b & CanID::BIT_BRAKE_SYSTEM   );
        m_model->setBatteryFault(b & CanID::BIT_BATTERY_FAULT  );
        m_model->setAirbagFault (b & CanID::BIT_AIRBAG_FAULT   );
        m_model->setLowBeam     (b & CanID::BIT_LOW_BEAM       );
        m_model->setHighBeam    (b & CanID::BIT_HIGH_BEAM      );
        m_model->setFogLights   (b & CanID::BIT_FOG_LIGHTS     );
        break;
    }

    case CanID::GEAR:
        // byte 0: 0 = N, 1-6 = передача
        m_model->setCurrentGear(static_cast<int>(u8(0)));
        break;

    default:
        break;
    }
}

void CANReader::setStatus(const QString &text)
{
    {
        QMutexLocker lock(&m_mutex);
        if (m_statusText == text) return;
        m_statusText = text;
    }
    emit statusChanged();
}
