// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Shell — D-Bus Client
//
// Communicates with aurion-ai and aurion-hwcompat system services.

#ifndef DBUSCLIENT_H
#define DBUSCLIENT_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class DBusClient : public QObject
{
    Q_OBJECT

public:
    explicit DBusClient(QObject *parent = nullptr);
    ~DBusClient();

    // --- AI Service (org.aurion.AI) ---

    // Send a question to the AI assistant with optional context
    Q_INVOKABLE void askAI(const QString &question, const QString &context = QString());

    // Request hardware diagnosis for a specific device
    Q_INVOKABLE void diagnoseDevice(const QString &deviceId);

    // --- Hardware Compat Service (org.aurion.HardwareCompat) ---

    // Trigger a full hardware scan
    Q_INVOKABLE void scanHardware();

    // Get status of a specific device
    Q_INVOKABLE void getDeviceInfo(const QString &deviceId);

    // --- Diagnostics Service (org.aurion.Diagnostics) ---

    // Collect system logs
    Q_INVOKABLE void collectLogs();

    // Create a system snapshot
    Q_INVOKABLE void createSnapshot(const QString &description);

signals:
    // AI responses
    void aiResponseReceived(const QString &response);
    void aiError(const QString &error);

    // Hardware scan results
    void hardwareScanComplete(const QVariantList &devices);
    void deviceInfoReceived(const QVariantMap &info);

    // Diagnostics
    void logsCollected(const QString &bundlePath);
    void snapshotCreated(const QString &snapshotId);

private:
    void initConnections();
};

#endif // DBUSCLIENT_H
