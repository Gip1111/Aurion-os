// SPDX-License-Identifier: GPL-3.0-or-later
#include "shellcontroller.h"
#include <QDebug>

#ifdef HAVE_LAYER_SHELL
#include <LayerShellQt/Window>
#endif

ShellController::ShellController(QObject *parent) : QObject(parent) {}

void ShellController::setLauncherVisible(bool v)
{
    if (m_launcherVisible != v) {
        m_launcherVisible = v;
        emit launcherVisibleChanged();
    }
}

void ShellController::setAiSidebarVisible(bool v)
{
    if (m_aiSidebarVisible != v) {
        m_aiSidebarVisible = v;
        emit aiSidebarVisibleChanged();
    }
}

void ShellController::toggleLauncher()
{
    setLauncherVisible(!m_launcherVisible);
    if (m_launcherVisible)
        setAiSidebarVisible(false);
}

void ShellController::toggleAiSidebar()
{
    setAiSidebarVisible(!m_aiSidebarVisible);
    if (m_aiSidebarVisible)
        setLauncherVisible(false);
}

void ShellController::configureLayerShell(QWindow *window, const QString &role)
{
    if (!window) return;

#ifdef HAVE_LAYER_SHELL
    auto *lsw = LayerShellQt::Window::get(window);

    if (role == "topbar") {
        lsw->setLayer(LayerShellQt::Window::LayerTop);
        lsw->setAnchors(LayerShellQt::Window::AnchorTop
                       | LayerShellQt::Window::AnchorLeft
                       | LayerShellQt::Window::AnchorRight);
        lsw->setExclusiveZone(36);
        lsw->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
        lsw->setScope("aurion-topbar");
    }
    else if (role == "dock") {
        lsw->setLayer(LayerShellQt::Window::LayerTop);
        lsw->setAnchors(LayerShellQt::Window::AnchorBottom);
        lsw->setExclusiveZone(0); // floating, no exclusive zone
        lsw->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
        lsw->setScope("aurion-dock");
    }
    else if (role == "launcher") {
        lsw->setLayer(LayerShellQt::Window::LayerOverlay);
        lsw->setAnchors(LayerShellQt::Window::AnchorTop
                       | LayerShellQt::Window::AnchorBottom
                       | LayerShellQt::Window::AnchorLeft
                       | LayerShellQt::Window::AnchorRight);
        lsw->setExclusiveZone(-1); // cover everything
        lsw->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
        lsw->setScope("aurion-launcher");
    }
    else if (role == "aisidebar") {
        lsw->setLayer(LayerShellQt::Window::LayerOverlay);
        lsw->setAnchors(LayerShellQt::Window::AnchorTop
                       | LayerShellQt::Window::AnchorBottom
                       | LayerShellQt::Window::AnchorRight);
        lsw->setExclusiveZone(0);
        lsw->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
        lsw->setScope("aurion-aisidebar");
    }

    qDebug() << "[layer-shell] Configured" << role;
#else
    // Dev mode: just position windows manually
    if (role == "topbar") {
        window->setX(0);
        window->setY(0);
    } else if (role == "dock") {
        window->setX((1920 - window->width()) / 2);
        window->setY(1080 - window->height() - 16);
    }
    qDebug() << "[dev-mode] Positioned" << role;
#endif
}
