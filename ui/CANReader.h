#pragma once

#include <QObject>
#include <QThread>
#include <QTimer>
#include <QMutex>
#include <QString>
#include <QAtomicInt>

// ─── Forward declarations ─────────────────────────────────────────────────────
class DataModel;

// ─── CAN Frame IDs (тестовая таблица, 11-bit standard) ───────────────────────
// Меняй под свой ECU
namespace CanID {
static constexpr long SPEED       = 0x0B0;  // byte0-1: speed * 0.01 km/h  (uint16 big-endian)
static constexpr long RPM         = 0x0C0;  // byte0-1: rpm * 0.25          (uint16 big-endian)
static constexpr long ENGINE_TEMP = 0x130;  // byte0: temp + offset (-40°C) (uint8)
static constexpr long FUEL_LEVEL  = 0x145;  // byte0: fuel 0-100%           (uint8)
static constexpr long STATUS_1    = 0x200;  // byte0 bits: see below
static constexpr long STATUS_2    = 0x201;  // byte0 bits: see below
static constexpr long GEAR        = 0x210;  // byte0: gear 0-6

// STATUS_1 byte0 bits
static constexpr uint8_t BIT_CHECK_ENGINE  = 0x01;
static constexpr uint8_t BIT_ABS_ACTIVE    = 0x02;
static constexpr uint8_t BIT_ESP_ACTIVE    = 0x04;
static constexpr uint8_t BIT_TPMS          = 0x08;
static constexpr uint8_t BIT_FUEL_LOW      = 0x10;
static constexpr uint8_t BIT_SEATBELT      = 0x20;
static constexpr uint8_t BIT_TURN_LEFT     = 0x40;
static constexpr uint8_t BIT_TURN_RIGHT    = 0x80;

// STATUS_2 byte0 bits
static constexpr uint8_t BIT_OIL_PRESSURE  = 0x01;
static constexpr uint8_t BIT_OVERHEATING   = 0x02;
static constexpr uint8_t BIT_BRAKE_SYSTEM  = 0x04;
static constexpr uint8_t BIT_BATTERY_FAULT = 0x08;
static constexpr uint8_t BIT_AIRBAG_FAULT  = 0x10;
static constexpr uint8_t BIT_LOW_BEAM      = 0x20;
static constexpr uint8_t BIT_HIGH_BEAM     = 0x40;
static constexpr uint8_t BIT_FOG_LIGHTS    = 0x80;
}

// ─── Worker: живёт в отдельном QThread ───────────────────────────────────────
class CANWorker : public QObject
{
    Q_OBJECT
public:
    explicit CANWorker(QObject *parent = nullptr);
    ~CANWorker() override;

public slots:
    void connectDevice(int channel, int bitrate);
    void disconnectDevice();
    void poll();                    // вызывается по таймеру

signals:
    void frameReceived(long id, QByteArray data);
    void connected();
    void disconnected();
    void errorOccurred(const QString &msg);

private:
    int    m_handle  = -1;          // canHandle
    bool   m_open    = false;
    QTimer *m_timer  = nullptr;

    static constexpr int POLL_INTERVAL_MS = 10;
    static constexpr int FRAMES_PER_POLL  = 64;
};

// ─── CANReader: публичный класс, экспортируется в QML ────────────────────────
class CANReader : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool    connected  READ isConnected  NOTIFY connectionChanged)
    Q_PROPERTY(QString statusText READ statusText   NOTIFY statusChanged)
    Q_PROPERTY(int     channel    READ channel      WRITE setChannel    NOTIFY channelChanged)
    Q_PROPERTY(int     bitrate    READ bitrate      WRITE setBitrate    NOTIFY bitrateChanged)
    Q_PROPERTY(int     frameCount READ frameCount   NOTIFY frameCountChanged)

public:
    explicit CANReader(DataModel *model, QObject *parent = nullptr);
    ~CANReader() override;

    bool    isConnected() const;
    QString statusText()  const;
    int     channel()     const { return m_channel; }
    int     bitrate()     const { return m_bitrate; }
    int     frameCount()  const { return m_frameCount; }

    void    setChannel(int v);
    void    setBitrate(int v);

public slots:
    Q_INVOKABLE void connectDevice();
    Q_INVOKABLE void disconnectDevice();

signals:
    void connectionChanged();
    void statusChanged();
    void channelChanged();
    void bitrateChanged();
    void frameCountChanged();

private slots:
    void onFrame(long id, QByteArray data);
    void onConnected();
    void onDisconnected();
    void onError(const QString &msg);

private:
    void decodeFrame(long id, const QByteArray &data);
    void setStatus(const QString &text);

    DataModel  *m_model      = nullptr;
    CANWorker  *m_worker     = nullptr;
    QThread    *m_thread     = nullptr;

    bool        m_connected  = false;
    QString     m_statusText = "Не подключён";
    int         m_channel    = 0;       // Kvaser channel index (0-based)
    int         m_bitrate    = 500000;  // 500 kbit/s по умолчанию
    int         m_frameCount = 0;

    mutable QMutex m_mutex;
};
