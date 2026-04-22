// SPDX-License-Identifier: GPL-3.0-or-later
#include "shelladaptor.h"
#include <QDebug>

ShellAdaptor::ShellAdaptor(ShellController *controller)
    : QDBusAbstractAdaptor(controller)
    , m_controller(controller)
{
    setAutoRelaySignals(true);
}

void ShellAdaptor::ToggleLauncher()
{
    qDebug() << "[D-Bus] ToggleLauncher called";
    m_controller->toggleLauncher();
}

void ShellAdaptor::ToggleAISidebar()
{
    qDebug() << "[D-Bus] ToggleAISidebar called";
    m_controller->toggleAiSidebar();
}

bool ShellAdaptor::GetLauncherVisible()
{
    return m_controller->launcherVisible();
}

bool ShellAdaptor::GetAISidebarVisible()
{
    return m_controller->aiSidebarVisible();
}
