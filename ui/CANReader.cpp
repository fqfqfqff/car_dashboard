#include "CANReader.h"

#include "backend/DataModel.h"

#include <QBluetoothDeviceInfo>
#include <QBluetoothPermission>
#include <QBluetoothServiceInfo>
#include <QBluetoothUuid>
#include <QCoreApplication>
#include <QDebug>
#include <QLocationPermission>
#include <QRegularExpression>
#include <QSettings>
#include <QTimer>

#ifdef Q_OS_ANDROID
#include <QtCore/qcoreapplication_platform.h>
#endif

#include <array>

namespace {

constexpr int kResetTimeoutMs = 3000;
constexpr int kInitTimeoutMs = 1500;
constexpr int kPollTimeoutMs = 1200;
constexpr int kMaxConsecutiveTimeouts = 8;

const std::array<const char *, 6> kInitCommands = {
    "ATZ",
    "ATE0",
    "ATL0",
    "ATS0",
    "ATH0",
    "ATSP0"
};

struct PollCommand {
    const char *request;
    quint8 pid;
};

const std::array<PollCommand, 8> kPollSequence = {{
    { "010C", 0x0C },
    { "010D", 0x0D },
    { "010C", 0x0C },
    { "010D", 0x0D },
    { "0104", 0x04 },
    { "0105", 0x05 },
    { "012F", 0x2F },
    { "0142", 0x42 }
}};

QRegularExpression candidateRegex()
{
    return QRegularExpression(
        QStringLiteral("(ELM|OBD|V-?LINK|ICAR|SCANTOOL|SCAN|ADAPTER)"),
        QRegularExpression::CaseInsensitiveOption);
}

} // namespace

CANReader::CANReader(DataModel *model, QObject *parent)
    : QObject(parent)
    , m_model(model)
    , m_socket(new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol, this))
    , m_discoveryAgent(new QBluetoothDeviceDiscoveryAgent(this))
    , m_reconnectTimer(new QTimer(this))
    , m_commandTimeoutTimer(new QTimer(this))
    , m_pollTimer(new QTimer(this))
{
    const QSettings settings;

    m_adapterAddress = normalizedHexAddress(settings.value(QStringLiteral("obd/adapterAddress")).toString());
    m_adapterName = settings.value(QStringLiteral("obd/adapterName")).toString().trimmed();
    m_autoConnect = settings.value(QStringLiteral("obd/autoConnect"), m_autoConnect).toBool();
    m_pollIntervalMs = qBound(50, settings.value(QStringLiteral("obd/pollIntervalMs"), m_pollIntervalMs).toInt(), 1000);
    m_reconnectDelayMs = qBound(1000, settings.value(QStringLiteral("obd/reconnectDelayMs"), m_reconnectDelayMs).toInt(), 30000);

    const QString envAddress = normalizedHexAddress(qEnvironmentVariable("CAR_DASHBOARD_ELM327_ADDRESS"));
    if (!envAddress.isEmpty()) {
        m_adapterAddress = envAddress;
    }

    const QString envName = qEnvironmentVariable("CAR_DASHBOARD_ELM327_NAME").trimmed();
    if (!envName.isEmpty()) {
        m_adapterName = envName;
    }

    bool ok = false;
    const int envPollMs = qEnvironmentVariableIntValue("CAR_DASHBOARD_ELM327_POLL_MS", &ok);
    if (ok) {
        m_pollIntervalMs = qBound(50, envPollMs, 1000);
    }

    connect(m_socket, &QBluetoothSocket::connected, this, &CANReader::onSocketConnected);
    connect(m_socket, &QBluetoothSocket::disconnected, this, &CANReader::onSocketDisconnected);
    connect(m_socket, &QBluetoothSocket::readyRead, this, &CANReader::onSocketReadyRead);
    connect(m_socket, &QBluetoothSocket::errorOccurred, this, &CANReader::onSocketError);

    connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
            this, &CANReader::onDeviceDiscovered);
    connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::finished,
            this, &CANReader::onDiscoveryFinished);
    connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::errorOccurred,
            this, &CANReader::onDiscoveryError);

    m_reconnectTimer->setSingleShot(true);
    m_reconnectTimer->setInterval(m_reconnectDelayMs);
    connect(m_reconnectTimer, &QTimer::timeout, this, [this]() {
        if (m_connectRequested && !m_manualDisconnect) {
            connectDevice();
        }
    });

    m_commandTimeoutTimer->setSingleShot(true);
    connect(m_commandTimeoutTimer, &QTimer::timeout, this, [this]() {
        if (m_phase == Phase::Initializing) {
            qWarning() << "[CANReader] init timeout for" << m_pendingCommand;
            m_pendingCommand.clear();
            sendNextInitCommand();
            return;
        }

        if (m_phase != Phase::Polling)
            return;

        ++m_consecutiveTimeouts;
        qWarning() << "[CANReader] PID timeout for" << m_pendingCommand
                   << "count=" << m_consecutiveTimeouts;
        m_pendingCommand.clear();

        if (m_consecutiveTimeouts >= kMaxConsecutiveTimeouts) {
            scheduleReconnect(QStringLiteral("ELM327 response timeout"));
            return;
        }

        m_pollTimer->start(m_pollIntervalMs);
    });

    m_pollTimer->setSingleShot(true);
    m_pollTimer->setInterval(m_pollIntervalMs);
    connect(m_pollTimer, &QTimer::timeout, this, &CANReader::sendNextPollCommand);

    if (m_autoConnect) {
        QTimer::singleShot(1500, this, &CANReader::connectDevice);
    }
}

CANReader::~CANReader()
{
    m_manualDisconnect = true;
    m_connectRequested = false;
    stopDiscovery();
    m_reconnectTimer->stop();
    m_commandTimeoutTimer->stop();
    m_pollTimer->stop();

    if (m_socket->state() != QBluetoothSocket::UnconnectedState)
        m_socket->abort();
}

void CANReader::setAdapterAddress(const QString &value)
{
    const QString normalized = normalizedHexAddress(value);
    if (m_adapterAddress == normalized)
        return;

    m_adapterAddress = normalized;

    QSettings settings;
    settings.setValue(QStringLiteral("obd/adapterAddress"), m_adapterAddress);

    emit adapterAddressChanged();
}

void CANReader::setAutoConnect(bool value)
{
    if (m_autoConnect == value)
        return;

    m_autoConnect = value;

    QSettings settings;
    settings.setValue(QStringLiteral("obd/autoConnect"), m_autoConnect);

    emit autoConnectChanged();
}

void CANReader::setPollInterval(int value)
{
    const int bounded = qBound(50, value, 1000);
    if (m_pollIntervalMs == bounded)
        return;

    m_pollIntervalMs = bounded;

    QSettings settings;
    settings.setValue(QStringLiteral("obd/pollIntervalMs"), m_pollIntervalMs);

    m_pollTimer->setInterval(m_pollIntervalMs);
    emit pollIntervalChanged();
}

void CANReader::setReconnectDelay(int value)
{
    const int bounded = qBound(1000, value, 30000);
    if (m_reconnectDelayMs == bounded)
        return;

    m_reconnectDelayMs = bounded;

    QSettings settings;
    settings.setValue(QStringLiteral("obd/reconnectDelayMs"), m_reconnectDelayMs);

    m_reconnectTimer->setInterval(m_reconnectDelayMs);
    emit reconnectDelayChanged();
}

void CANReader::connectDevice()
{
    if (m_phase == Phase::Connecting
        || m_phase == Phase::Discovering
        || m_phase == Phase::Initializing
        || m_phase == Phase::Polling) {
        return;
    }

    m_manualDisconnect = false;
    m_connectRequested = true;
    m_discoveryFallbackTried = false;
    m_reconnectTimer->stop();

    if (!ensurePermissions())
        return;

    continueConnectionFlow();
}

void CANReader::disconnectDevice()
{
    m_manualDisconnect = true;
    m_connectRequested = false;

    stopDiscovery();
    m_reconnectTimer->stop();
    m_commandTimeoutTimer->stop();
    m_pollTimer->stop();
    m_pendingCommand.clear();
    m_phase = Phase::Disconnecting;

    if (m_socket->state() != QBluetoothSocket::UnconnectedState) {
        m_socket->abort();
    } else {
        setConnectedState(false);
        m_phase = Phase::Idle;
        setStatus(QStringLiteral("ELM327 disconnected"));
    }
}

bool CANReader::ensurePermissions()
{
#ifdef Q_OS_ANDROID
    if (m_permissionRequestInFlight)
        return false;

    QBluetoothPermission bluetoothPermission;
#if QT_VERSION >= QT_VERSION_CHECK(6, 6, 0)
    bluetoothPermission.setCommunicationModes(QBluetoothPermission::Access);
#endif

    const auto btStatus = qApp->checkPermission(bluetoothPermission);
    if (btStatus == Qt::PermissionStatus::Undetermined) {
        m_permissionRequestInFlight = true;
        m_phase = Phase::PermissionPending;
        setStatus(QStringLiteral("Requesting Bluetooth permission"));
        qApp->requestPermission(bluetoothPermission, this, [this, bluetoothPermission](const QPermission &) {
            m_permissionRequestInFlight = false;
            if (qApp->checkPermission(bluetoothPermission) == Qt::PermissionStatus::Granted) {
                if (ensureDiscoveryPermissions())
                    continueConnectionFlow();
            } else {
                m_connectRequested = false;
                m_phase = Phase::Idle;
                setStatus(QStringLiteral("Bluetooth permission denied"));
            }
        });
        return false;
    }

    if (btStatus != Qt::PermissionStatus::Granted) {
        m_connectRequested = false;
        setStatus(QStringLiteral("Bluetooth permission denied"));
        return false;
    }
#endif

    return ensureDiscoveryPermissions();
}

bool CANReader::ensureDiscoveryPermissions()
{
#ifdef Q_OS_ANDROID
    if (!m_adapterAddress.isEmpty() && !m_discoveryFallbackTried)
        return true;

    if (QNativeInterface::QAndroidApplication::sdkVersion() >= 31)
        return true;

    if (m_permissionRequestInFlight)
        return false;

    QLocationPermission locationPermission;
    locationPermission.setAccuracy(QLocationPermission::Precise);
    locationPermission.setAvailability(QLocationPermission::WhenInUse);

    const auto locationStatus = qApp->checkPermission(locationPermission);
    if (locationStatus == Qt::PermissionStatus::Undetermined) {
        m_permissionRequestInFlight = true;
        m_phase = Phase::PermissionPending;
        setStatus(QStringLiteral("Requesting location permission"));
        qApp->requestPermission(locationPermission, this, [this, locationPermission](const QPermission &) {
            m_permissionRequestInFlight = false;
            if (qApp->checkPermission(locationPermission) == Qt::PermissionStatus::Granted) {
                continueConnectionFlow();
            } else {
                m_connectRequested = false;
                m_phase = Phase::Idle;
                setStatus(QStringLiteral("Location permission denied"));
            }
        });
        return false;
    }

    if (locationStatus != Qt::PermissionStatus::Granted) {
        m_connectRequested = false;
        setStatus(QStringLiteral("Location permission denied"));
        return false;
    }
#endif

    return true;
}

void CANReader::continueConnectionFlow()
{
    if (!m_connectRequested)
        return;

    if (m_phase == Phase::Discovering
        || m_phase == Phase::Connecting
        || m_phase == Phase::Initializing
        || m_phase == Phase::Polling) {
        return;
    }

    resetConnectionState(false);
    m_phase = Phase::Idle;

    if (m_discoveryFallbackTried) {
        startDiscovery();
        return;
    }

    if (!m_adapterAddress.isEmpty()) {
        const QBluetoothAddress address(m_adapterAddress);
        if (!address.isNull()) {
            connectToDevice(address, m_adapterName);
            return;
        }
    }

    startDiscovery();
}

void CANReader::startDiscovery()
{
    if (!(QBluetoothDeviceDiscoveryAgent::supportedDiscoveryMethods()
          & QBluetoothDeviceDiscoveryAgent::ClassicMethod)) {
        m_connectRequested = false;
        setStatus(QStringLiteral("Classic Bluetooth discovery is not available"));
        return;
    }

    stopDiscovery();
    resetConnectionState(false);

    m_phase = Phase::Discovering;
    setStatus(QStringLiteral("Scanning for ELM327 adapter"));
    m_discoveryAgent->start(QBluetoothDeviceDiscoveryAgent::ClassicMethod);
}

void CANReader::stopDiscovery()
{
    if (m_discoveryAgent->isActive())
        m_discoveryAgent->stop();
}

void CANReader::connectToDevice(const QBluetoothAddress &address, const QString &name)
{
    if (address.isNull()) {
        setStatus(QStringLiteral("Invalid Bluetooth adapter address"));
        return;
    }

    stopDiscovery();
    resetConnectionState(false);

    m_phase = Phase::Connecting;
    m_adapterName = name.trimmed();
    emit adapterNameChanged();

    if (m_socket->state() != QBluetoothSocket::UnconnectedState)
        m_socket->abort();

    setStatus(QStringLiteral("Connecting to %1").arg(name.isEmpty() ? address.toString() : name));
    m_socket->connectToService(address,
                               QBluetoothUuid(QBluetoothUuid::ServiceClassUuid::SerialPort),
                               QIODeviceBase::ReadWrite);
}

void CANReader::resetConnectionState(bool clearAdapter)
{
    m_commandTimeoutTimer->stop();
    m_pollTimer->stop();
    m_pendingCommand.clear();
    m_rxBuffer.clear();
    m_initIndex = 0;
    m_pollIndex = 0;
    m_consecutiveTimeouts = 0;

    if (m_frameCount != 0) {
        m_frameCount = 0;
        emit frameCountChanged();
    }

    setConnectedState(false);

    if (clearAdapter) {
        if (!m_adapterAddress.isEmpty()) {
            m_adapterAddress.clear();
            emit adapterAddressChanged();
        }
        if (!m_adapterName.isEmpty()) {
            m_adapterName.clear();
            emit adapterNameChanged();
        }
    }
}

void CANReader::scheduleReconnect(const QString &reason)
{
    stopDiscovery();
    m_commandTimeoutTimer->stop();
    m_pollTimer->stop();
    m_pendingCommand.clear();
    m_rxBuffer.clear();
    setConnectedState(false);
    m_phase = Phase::Disconnecting;

    if (m_socket->state() != QBluetoothSocket::UnconnectedState) {
        m_socket->abort();
    } else {
        m_phase = Phase::Idle;
    }

    if (m_manualDisconnect || !m_autoConnect || !m_connectRequested) {
        setStatus(reason);
        return;
    }

    setStatus(QStringLiteral("%1, retry in %2 s")
                  .arg(reason)
                  .arg(m_reconnectDelayMs / 1000));
    m_reconnectTimer->start(m_reconnectDelayMs);
}

void CANReader::sendCommand(const QString &command, int timeoutMs)
{
    if (m_socket->state() != QBluetoothSocket::ConnectedState)
        return;

    QByteArray payload = command.toLatin1();
    payload.append('\r');

    const qint64 written = m_socket->write(payload);
    if (written != payload.size()) {
        scheduleReconnect(QStringLiteral("ELM327 write failure"));
        return;
    }

    m_pendingCommand = command;
    m_commandTimeoutTimer->start(timeoutMs);
}

void CANReader::sendNextInitCommand()
{
    if (m_phase != Phase::Initializing)
        return;

    if (m_initIndex >= static_cast<int>(kInitCommands.size())) {
        m_phase = Phase::Polling;
        setConnectedState(true);
        setStatus(QStringLiteral("ELM327 connected: %1").arg(adapterDisplayName()));
        m_pollTimer->start(0);
        return;
    }

    const QString command = QString::fromLatin1(kInitCommands.at(m_initIndex));
    ++m_initIndex;
    sendCommand(command, command == QStringLiteral("ATZ") ? kResetTimeoutMs : kInitTimeoutMs);
}

void CANReader::sendNextPollCommand()
{
    if (m_phase != Phase::Polling || !m_pendingCommand.isEmpty())
        return;

    const PollCommand &command = kPollSequence.at(m_pollIndex);
    m_pollIndex = (m_pollIndex + 1) % static_cast<int>(kPollSequence.size());

    sendCommand(QString::fromLatin1(command.request), kPollTimeoutMs);
}

void CANReader::handleResponseBlock(const QString &block)
{
    QStringList lines;
    const QStringList rawLines = block.split(QRegularExpression(QStringLiteral("[\\r\\n]+")),
                                             Qt::SkipEmptyParts);
    lines.reserve(rawLines.size());

    const QString pendingUpper = m_pendingCommand.toUpper();
    for (const QString &rawLine : rawLines) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty())
            continue;

        QString compact = line;
        compact.remove(QLatin1Char(' '));
        if (compact.toUpper() == pendingUpper)
            continue;

        lines.append(line);
    }

    m_commandTimeoutTimer->stop();

    if (m_phase == Phase::Initializing) {
        m_pendingCommand.clear();
        handleInitResponse(lines);
        return;
    }

    if (m_phase == Phase::Polling) {
        m_consecutiveTimeouts = 0;
        m_pendingCommand.clear();
        handlePollResponse(lines);
    }
}

void CANReader::handleInitResponse(const QStringList &lines)
{
    for (const QString &line : lines) {
        const QString upper = line.toUpper();
        if (upper.contains(QStringLiteral("UNABLE TO CONNECT"))
            || upper.contains(QStringLiteral("NO DATA"))
            || upper.contains(QStringLiteral("ERROR"))) {
            scheduleReconnect(QStringLiteral("ELM327 init failed"));
            return;
        }
    }

    sendNextInitCommand();
}

void CANReader::handlePollResponse(const QStringList &lines)
{
    bool hasUsefulFrame = false;

    for (const QByteArray &frame : extractFrames(lines)) {
        if (frame.size() < 3)
            continue;

        if (static_cast<quint8>(frame.at(0)) != 0x41)
            continue;

        applyPid(static_cast<quint8>(frame.at(1)), frame.mid(2));
        hasUsefulFrame = true;
    }

    if (hasUsefulFrame) {
        ++m_frameCount;
        emit frameCountChanged();
    }

    if (m_phase == Phase::Polling)
        m_pollTimer->start(m_pollIntervalMs);
}

QList<QByteArray> CANReader::extractFrames(const QStringList &lines) const
{
    QList<QByteArray> frames;
    frames.reserve(lines.size());

    for (const QString &line : lines) {
        const QString upper = line.toUpper();

        if (upper.contains(QStringLiteral("SEARCHING"))
            || upper.contains(QStringLiteral("BUS INIT"))
            || upper == QStringLiteral("OK")
            || upper == QStringLiteral("?")
            || upper.contains(QStringLiteral("NO DATA"))
            || upper.contains(QStringLiteral("STOPPED"))) {
            continue;
        }

        QString compact = upper;
        compact.remove(QRegularExpression(QStringLiteral("[^0-9A-F]")));
        if (compact.size() < 6 || (compact.size() % 2) != 0)
            continue;

        const QByteArray payload = QByteArray::fromHex(compact.toLatin1());
        if (!payload.isEmpty())
            frames.append(payload);
    }

    return frames;
}

bool CANReader::isCandidateDevice(const QBluetoothDeviceInfo &info) const
{
    const QString address = normalizedHexAddress(info.address().toString());
    if (!m_adapterAddress.isEmpty() && address == m_adapterAddress)
        return true;

    const QString name = info.name().trimmed();
    if (m_discoveryFallbackTried)
        return !name.isEmpty() && candidateRegex().match(name).hasMatch();

    if (!m_adapterAddress.isEmpty())
        return address == m_adapterAddress;

    return !name.isEmpty() && candidateRegex().match(name).hasMatch();
}

void CANReader::applyPid(quint8 pid, const QByteArray &payload)
{
    if (!m_model)
        return;

    switch (pid) {
    case 0x0C:
        if (payload.size() >= 2) {
            const double rpm =
                ((static_cast<quint8>(payload.at(0)) << 8) | static_cast<quint8>(payload.at(1))) / 4.0;
            m_model->setRpm(rpm);
        }
        break;

    case 0x0D:
        if (payload.size() >= 1)
            m_model->setSpeed(static_cast<quint8>(payload.at(0)));
        break;

    case 0x05:
        if (payload.size() >= 1)
            m_model->setEngineTemp(static_cast<quint8>(payload.at(0)) - 40.0);
        break;

    case 0x2F:
        if (payload.size() >= 1)
            m_model->setFuelLevel(static_cast<quint8>(payload.at(0)) * 100.0 / 255.0);
        break;

    case 0x42:
        if (payload.size() >= 2) {
            const double voltage =
                ((static_cast<quint8>(payload.at(0)) << 8) | static_cast<quint8>(payload.at(1))) / 1000.0;
            m_model->setBatteryVoltage(voltage);
        }
        break;

    case 0x04:
        if (payload.size() >= 1)
            m_model->setEngineLoad(static_cast<quint8>(payload.at(0)) * 100.0 / 255.0);
        break;

    default:
        break;
    }
}

void CANReader::setConnectedState(bool connected)
{
    if (m_connected == connected)
        return;

    m_connected = connected;
    emit connectionChanged();

    if (m_model) {
        m_model->setCanConnected(connected);
        m_model->setEngineRunning(connected);
    }
}

void CANReader::setStatus(const QString &text)
{
    if (m_statusText == text)
        return;

    m_statusText = text;
    emit statusChanged();
}

QString CANReader::adapterDisplayName() const
{
    if (!m_adapterName.isEmpty() && !m_adapterAddress.isEmpty())
        return QStringLiteral("%1 (%2)").arg(m_adapterName, m_adapterAddress);
    if (!m_adapterName.isEmpty())
        return m_adapterName;
    if (!m_adapterAddress.isEmpty())
        return m_adapterAddress;
    return QStringLiteral("ELM327");
}

QString CANReader::normalizedHexAddress(const QString &value) const
{
    QString normalized = value.trimmed().toUpper();
    normalized.remove(QRegularExpression(QStringLiteral("[^0-9A-F:]")));
    return normalized;
}

void CANReader::onSocketConnected()
{
    const QString peerAddress = normalizedHexAddress(m_socket->peerAddress().toString());
    if (!peerAddress.isEmpty())
        setAdapterAddress(peerAddress);

    const QString peerName = m_socket->peerName().trimmed();
    if (!peerName.isEmpty() && m_adapterName != peerName) {
        m_adapterName = peerName;
        QSettings settings;
        settings.setValue(QStringLiteral("obd/adapterName"), m_adapterName);
        emit adapterNameChanged();
    }

    m_phase = Phase::Initializing;
    m_initIndex = 0;
    m_pollIndex = 0;
    m_consecutiveTimeouts = 0;
    m_rxBuffer.clear();
    setStatus(QStringLiteral("Initializing ELM327"));
    sendNextInitCommand();
}

void CANReader::onSocketDisconnected()
{
    const bool expectedDisconnect = m_manualDisconnect || m_phase == Phase::Disconnecting;

    m_commandTimeoutTimer->stop();
    m_pollTimer->stop();
    m_pendingCommand.clear();
    m_rxBuffer.clear();
    setConnectedState(false);
    m_phase = Phase::Idle;

    if (expectedDisconnect) {
        if (m_manualDisconnect)
            setStatus(QStringLiteral("ELM327 disconnected"));
        return;
    }

    scheduleReconnect(QStringLiteral("Bluetooth connection lost"));
}

void CANReader::onSocketReadyRead()
{
    m_rxBuffer.append(QString::fromLatin1(m_socket->readAll()));

    int promptIndex = m_rxBuffer.indexOf(QLatin1Char('>'));
    while (promptIndex >= 0) {
        const QString block = m_rxBuffer.left(promptIndex);
        m_rxBuffer.remove(0, promptIndex + 1);
        handleResponseBlock(block);
        promptIndex = m_rxBuffer.indexOf(QLatin1Char('>'));
    }
}

void CANReader::onSocketError(QBluetoothSocket::SocketError error)
{
    if (m_manualDisconnect || m_phase == Phase::Disconnecting)
        return;

    const QString errorText = m_socket->errorString().trimmed();
    qWarning() << "[CANReader] socket error" << error << errorText;

    if (m_phase == Phase::Connecting
        && !m_adapterAddress.isEmpty()
        && !m_discoveryFallbackTried) {
        m_discoveryFallbackTried = true;
        if (ensureDiscoveryPermissions()) {
            startDiscovery();
        }
        return;
    }

    scheduleReconnect(errorText.isEmpty() ? QStringLiteral("Bluetooth socket error") : errorText);
}

void CANReader::onDeviceDiscovered(const QBluetoothDeviceInfo &info)
{
    if (m_phase != Phase::Discovering || !isCandidateDevice(info))
        return;

    const QString address = normalizedHexAddress(info.address().toString());
    const QString name = info.name().trimmed();

    if (!address.isEmpty())
        setAdapterAddress(address);

    if (m_adapterName != name) {
        m_adapterName = name;
        QSettings settings;
        settings.setValue(QStringLiteral("obd/adapterName"), m_adapterName);
        emit adapterNameChanged();
    }

    stopDiscovery();
    connectToDevice(QBluetoothAddress(address), name);
}

void CANReader::onDiscoveryFinished()
{
    if (m_phase != Phase::Discovering)
        return;

    scheduleReconnect(QStringLiteral("ELM327 adapter not found"));
}

void CANReader::onDiscoveryError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    Q_UNUSED(error);

    if (m_phase != Phase::Discovering)
        return;

    scheduleReconnect(m_discoveryAgent->errorString().trimmed().isEmpty()
                          ? QStringLiteral("Bluetooth discovery failed")
                          : m_discoveryAgent->errorString().trimmed());
}
