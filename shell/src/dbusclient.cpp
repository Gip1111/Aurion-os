// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Shell — D-Bus Client (MVP)
// Calls aurion-ai and aurion-hwcompat services.

#include "dbusclient.h"
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDebug>

DBusClient::DBusClient(QObject *parent) : QObject(parent)
{
    qDebug() << "[dbus-client] Initialized";
}

DBusClient::~DBusClient() = default;

void DBusClient::askAI(const QString &question, const QString &context)
{
    QDBusInterface iface("org.aurion.AI", "/org/aurion/AI",
                         "org.aurion.AI", QDBusConnection::sessionBus());

    if (!iface.isValid()) {
        qWarning() << "[dbus-client] AI service not available, using fallback";
        // Emit a helpful fallback response
        emit aiResponseReceived(
            "AI service is not running yet.\n\n"
            "To start it:\n"
            "1. cd ai-services\n"
            "2. pip install -e .\n"
            "3. python -m aurion_ai.service\n\n"
            "Or install the systemd service:\n"
            "systemctl --user start aurion-ai"
        );
        return;
    }

    // Async D-Bus call
    QDBusPendingCall call = iface.asyncCall("Ask", question, context);
    auto *watcher = new QDBusPendingCallWatcher(call, this);

    connect(watcher, &QDBusPendingCallWatcher::finished,
            this, [this](QDBusPendingCallWatcher *w) {
        QDBusPendingReply<QString> reply = *w;
        if (reply.isError()) {
            qWarning() << "[dbus-client] AI call failed:" << reply.error().message();
            emit aiResponseReceived("Error: " + reply.error().message());
        } else {
            emit aiResponseReceived(reply.value());
        }
        w->deleteLater();
    });
}

void DBusClient::diagnoseDevice(const QString &deviceId)
{
    askAI("Diagnose device: " + deviceId, "hardware-diagnosis");
}

void DBusClient::scanHardware()
{
    // TODO: Call org.aurion.HardwareCompat.ScanAll on system bus
    qDebug() << "[dbus-client] Hardware scan requested (not yet connected)";
    emit hardwareScanComplete(QVariantList());
}

void DBusClient::getDeviceInfo(const QString &deviceId)
{
    Q_UNUSED(deviceId)
    emit deviceInfoReceived(QVariantMap());
}

void DBusClient::collectLogs()
{
    qDebug() << "[dbus-client] Log collection requested";
    emit logsCollected("/tmp/aurion-logs-stub.tar.gz");
}

void DBusClient::createSnapshot(const QString &description)
{
    Q_UNUSED(description)
    emit snapshotCreated("snapshot-stub");
}
