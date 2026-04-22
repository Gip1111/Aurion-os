// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Shell — Shell Controller (MVP implementation)

#ifndef SHELLCONTROLLER_H
#define SHELLCONTROLLER_H

#include <QObject>
#include <QWindow>

class ShellController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool launcherVisible READ launcherVisible WRITE setLauncherVisible NOTIFY launcherVisibleChanged)
    Q_PROPERTY(bool aiSidebarVisible READ aiSidebarVisible WRITE setAiSidebarVisible NOTIFY aiSidebarVisibleChanged)

public:
    explicit ShellController(QObject *parent = nullptr);

    bool launcherVisible() const { return m_launcherVisible; }
    void setLauncherVisible(bool v);

    bool aiSidebarVisible() const { return m_aiSidebarVisible; }
    void setAiSidebarVisible(bool v);

    /// Configure a QWindow as a layer-shell surface.
    /// role: "topbar", "dock", "launcher", "aisidebar"
    Q_INVOKABLE void configureLayerShell(QWindow *window, const QString &role);

public slots:
    void toggleLauncher();
    void toggleAiSidebar();

signals:
    void launcherVisibleChanged();
    void aiSidebarVisibleChanged();

private:
    bool m_launcherVisible = false;
    bool m_aiSidebarVisible = false;
};

#endif
