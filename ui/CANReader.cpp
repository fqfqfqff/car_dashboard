#include "CANReader.h"
#include "backend/DataModel.h"
#include <QSettings>

#ifdef Q_OS_ANDROID

#include <QBluetoothDeviceInfo>
#include <QBluetoothPermission>
#include <QBluetoothServiceInfo>
#include <QBluetoothUuid>
#include <QCoreApplication>
#include <QDebug>
#include <QLocationPermission>
#include <QRegularExpression>
#include <QTimer>
#include <QtCore/qcoreapplication_platform.h>
#include <array>

// ... (весь существующий код CANReader.cpp остаётся здесь без изменений)
// ... вставь сюда всё от namespace { до последней функции }

#endif // Q_OS_ANDROID

// ── Заглушки для desktop-сборки ──────────────────────────────────────────────

#ifndef Q_OS_ANDROID

CANReader::CANReader(DataModel *model, QObject *parent)
    : QObject(parent)
    , m_model(model)
{
    setStatus(QStringLiteral("Bluetooth not available on desktop"));
}

CANReader::~CANReader() {}

void CANReader::setAdapterAddress(const QString &value)
{
    if (m_adapterAddress == value) return;
    m_adapterAddress = value;
    emit adapterAddressChanged();
}

void CANReader::setAutoConnect(bool value)
{
    if (m_autoConnect == value) return;
    m_autoConnect = value;
    emit autoConnectChanged();
}

void CANReader::setPollInterval(int value)
{
    if (m_pollIntervalMs == value) return;
    m_pollIntervalMs = value;
    emit pollIntervalChanged();
}

void CANReader::setReconnectDelay(int value)
{
    if (m_reconnectDelayMs == value) return;
    m_reconnectDelayMs = value;
    emit reconnectDelayChanged();
}

void CANReader::connectDevice()
{
    setStatus(QStringLiteral("Bluetooth not available on desktop"));
}

void CANReader::disconnectDevice()
{
    setConnectedState(false);
}

void CANReader::setConnectedState(bool connected)
{
    if (m_connected == connected) return;
    m_connected = connected;
    emit connectionChanged();
    if (m_model) {
        m_model->setCanConnected(connected);
        m_model->setEngineRunning(connected);
    }
}

void CANReader::setStatus(const QString &text)
{
    if (m_statusText == text) return;
    m_statusText = text;
    emit statusChanged();
}

QString CANReader::adapterDisplayName() const
{
    return QStringLiteral("N/A");
}

QString CANReader::normalizedHexAddress(const QString &value) const
{
    return value.trimmed().toUpper();
}

#endif // !Q_OS_ANDROID
