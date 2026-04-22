// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Shell — D-Bus Adaptor
// Exposes shell actions to the session bus so labwc keybindings work.

#ifndef SHELLADAPTOR_H
#define SHELLADAPTOR_H

#include <QDBusAbstractAdaptor>
#include "shellcontroller.h"

class ShellAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.aurion.Shell")

public:
    explicit ShellAdaptor(ShellController *controller);

public slots:
    Q_NOREPLY void ToggleLauncher();
    Q_NOREPLY void ToggleAISidebar();
    bool GetLauncherVisible();
    bool GetAISidebarVisible();

private:
    ShellController *m_controller;
};

#endif // SHELLADAPTOR_H
