#pragma once

#include <QBluetoothAddress>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothSocket>
#include <QByteArray>
#include <QList>
#include <QObject>
#include <QString>
#include <QStringList>

QT_BEGIN_NAMESPACE
class QBluetoothDeviceInfo;
class QTimer;
QT_END_NAMESPACE

class DataModel;

class CANReader : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool connected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    Q_PROPERTY(QString adapterAddress READ adapterAddress WRITE setAdapterAddress NOTIFY adapterAddressChanged)
    Q_PROPERTY(QString adapterName READ adapterName NOTIFY adapterNameChanged)
    Q_PROPERTY(bool autoConnect READ autoConnect WRITE setAutoConnect NOTIFY autoConnectChanged)
    Q_PROPERTY(int pollInterval READ pollInterval WRITE setPollInterval NOTIFY pollIntervalChanged)
    Q_PROPERTY(int reconnectDelay READ reconnectDelay WRITE setReconnectDelay NOTIFY reconnectDelayChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY frameCountChanged)

public:
    explicit CANReader(DataModel *model, QObject *parent = nullptr);
    ~CANReader() override;

    bool isConnected() const { return m_connected; }
    QString statusText() const { return m_statusText; }
    QString adapterAddress() const { return m_adapterAddress; }
    QString adapterName() const { return m_adapterName; }
    bool autoConnect() const { return m_autoConnect; }
    int pollInterval() const { return m_pollIntervalMs; }
    int reconnectDelay() const { return m_reconnectDelayMs; }
    int frameCount() const { return m_frameCount; }

    void setAdapterAddress(const QString &value);
    void setAutoConnect(bool value);
    void setPollInterval(int value);
    void setReconnectDelay(int value);

public slots:
    Q_INVOKABLE void connectDevice();
    Q_INVOKABLE void disconnectDevice();

signals:
    void connectionChanged();
    void statusChanged();
    void adapterAddressChanged();
    void adapterNameChanged();
    void autoConnectChanged();
    void pollIntervalChanged();
    void reconnectDelayChanged();
    void frameCountChanged();

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketReadyRead();
    void onSocketError(QBluetoothSocket::SocketError error);

    void onDeviceDiscovered(const QBluetoothDeviceInfo &info);
    void onDiscoveryFinished();
    void onDiscoveryError(QBluetoothDeviceDiscoveryAgent::Error error);

private:
    enum class Phase {
        Idle,
        PermissionPending,
        Discovering,
        Connecting,
        Initializing,
        Polling,
        Disconnecting
    };

    bool ensurePermissions();
    bool ensureDiscoveryPermissions();
    void continueConnectionFlow();
    void startDiscovery();
    void stopDiscovery();
    void connectToDevice(const QBluetoothAddress &address, const QString &name);
    void resetConnectionState(bool clearAdapter = false);
    void scheduleReconnect(const QString &reason);
    void sendCommand(const QString &command, int timeoutMs);
    void sendNextInitCommand();
    void sendNextPollCommand();
    void handleResponseBlock(const QString &block);
    void handleInitResponse(const QStringList &lines);
    void handlePollResponse(const QStringList &lines);
    QList<QByteArray> extractFrames(const QStringList &lines) const;
    bool isCandidateDevice(const QBluetoothDeviceInfo &info) const;
    void applyPid(quint8 pid, const QByteArray &payload);
    void setConnectedState(bool connected);
    void setStatus(const QString &text);
    QString adapterDisplayName() const;
    QString normalizedHexAddress(const QString &value) const;

    DataModel *m_model = nullptr;
    QBluetoothSocket *m_socket = nullptr;
    QBluetoothDeviceDiscoveryAgent *m_discoveryAgent = nullptr;
    QTimer *m_reconnectTimer = nullptr;
    QTimer *m_commandTimeoutTimer = nullptr;
    QTimer *m_pollTimer = nullptr;

    Phase m_phase = Phase::Idle;
    QString m_statusText = QStringLiteral("ELM327 not connected");
    QString m_adapterAddress;
    QString m_adapterName;
    QString m_rxBuffer;
    QString m_pendingCommand;

    int m_frameCount = 0;
    int m_pollIntervalMs = 120;
    int m_reconnectDelayMs = 3000;
    int m_initIndex = 0;
    int m_pollIndex = 0;
    int m_consecutiveTimeouts = 0;

    bool m_connected = false;
#ifdef Q_OS_ANDROID
    bool m_autoConnect = true;
#else
    bool m_autoConnect = false;
#endif
    bool m_manualDisconnect = false;
    bool m_connectRequested = false;
    bool m_permissionRequestInFlight = false;
    bool m_discoveryFallbackTried = false;
};
