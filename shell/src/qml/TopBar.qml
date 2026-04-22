// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS TopBar — MVP
// Glass panel: [logo] ... [clock] ... [tray icons] [AI btn]

import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: topBar
    color: "#A8111827"  // bg-base with alpha

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 1
        color: "#1E94A3B8"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 12
        spacing: 10

        // Logo / launcher trigger
        Text {
            text: "◆ aurion"
            font.family: "Inter"; font.pixelSize: 13; font.weight: Font.DemiBold
            color: "#6366F1"
            Layout.alignment: Qt.AlignVCenter
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: shellController.toggleLauncher()
            }
        }

        Item { Layout.fillWidth: true }

        // Clock
        Text {
            id: clock
            font.family: "Inter"; font.pixelSize: 13; font.weight: Font.Medium
            color: "#F1F5F9"
            Layout.alignment: Qt.AlignVCenter
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: clock.text = new Date().toLocaleTimeString(Qt.locale(), "ddd  HH:mm")
            }
        }

        Item { Layout.fillWidth: true }

        // Tray icons (placeholder text icons for MVP)
        Row {
            spacing: 8; Layout.alignment: Qt.AlignVCenter
            Text { text: "WiFi";  font.pixelSize: 11; color: "#94A3B8"; font.family: "Inter" }
            Text { text: "Vol";   font.pixelSize: 11; color: "#94A3B8"; font.family: "Inter" }
        }

        // AI toggle
        Rectangle {
            width: 60; height: 26; radius: 6
            color: aiMa.containsMouse ? "#406366F1" : "#206366F1"
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                text: "✦ AI"; font.family: "Inter"; font.pixelSize: 12; font.weight: Font.Medium
                color: "#818CF8"
            }
            MouseArea {
                id: aiMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: shellController.toggleAiSidebar()
            }
        }
    }
}
