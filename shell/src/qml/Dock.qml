// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Dock — MVP
// Floating glass dock with placeholder app items.

import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dock
    radius: 20
    color: "#A8111827"
    border.color: "#1E94A3B8"; border.width: 1

    property var apps: [
        { name: "Files",    icon: "📁", cmd: "thunar" },
        { name: "Terminal", icon: "🖥", cmd: "foot" },
        { name: "Browser",  icon: "🌐", cmd: "firefox" },
        { name: "Editor",   icon: "📝", cmd: "mousepad" },
        { name: "Install AurionOS", icon: "💿", cmd: "pkexec calamares" },
    ]

    Row {
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: dock.apps.length
            delegate: Rectangle {
                width: 46; height: 46; radius: 10
                color: ma.containsMouse ? "#2E1E293B" : "transparent"
                scale: ma.containsMouse ? 1.12 : 1.0

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: dock.apps[index].icon
                    font.pixelSize: 24
                }

                MouseArea {
                    id: ma; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var app = dock.apps[index]
                        console.log("[dock] Launch:", app.cmd)
                        Qt.openUrlExternally("exec:" + app.cmd)
                        // In production: use QProcess from C++
                    }
                }

                // Tooltip
                Rectangle {
                    visible: ma.containsMouse
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -30; width: tip.width + 12; height: 22; radius: 4
                    color: "#1E293B"; border.color: "#1E94A3B8"; border.width: 1
                    Text {
                        id: tip; anchors.centerIn: parent
                        text: dock.apps[index].name
                        font.family: "Inter"; font.pixelSize: 11; color: "#F1F5F9"
                    }
                }
            }
        }
    }
}
