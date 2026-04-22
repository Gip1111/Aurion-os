// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Shell — Main QML (MVP)
// Creates windows for each shell component.
// In layer-shell mode, windows are configured as overlay surfaces.
// In dev mode, windows are regular floating windows for testing.

import QtQuick 2.15
import QtQuick.Window 2.15

Item {
    id: root

    // --- Top Bar ---
    Window {
        id: topBarWin
        visible: true
        width: screenWidth
        height: 36
        color: "transparent"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

        Component.onCompleted: shellController.configureLayerShell(this, "topbar")

        TopBar {
            anchors.fill: parent
        }
    }

    // --- Dock ---
    Window {
        id: dockWin
        visible: true
        width: 400
        height: 60
        color: "transparent"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

        Component.onCompleted: shellController.configureLayerShell(this, "dock")

        Dock {
            anchors.fill: parent
        }
    }

    // --- Launcher Overlay ---
    Window {
        id: launcherWin
        visible: shellController.launcherVisible
        width: screenWidth
        height: screenHeight
        color: "transparent"
        flags: Qt.FramelessWindowHint

        Component.onCompleted: shellController.configureLayerShell(this, "launcher")

        Launcher {
            anchors.fill: parent
            onDismissed: shellController.setLauncherVisible(false)
        }

        onVisibleChanged: {
            if (visible) requestActivate()
        }
    }

    // --- AI Sidebar ---
    Window {
        id: sidebarWin
        visible: shellController.aiSidebarVisible
        width: 420
        height: screenHeight
        color: "transparent"
        flags: Qt.FramelessWindowHint

        Component.onCompleted: shellController.configureLayerShell(this, "aisidebar")

        AISidebar {
            anchors.fill: parent
            onCloseRequested: shellController.setAiSidebarVisible(false)
        }

        onVisibleChanged: {
            if (visible) requestActivate()
        }
    }
}
