// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS AI Sidebar — MVP
// Right-side chat panel with D-Bus integration to aurion-ai service.

import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: sidebar
    color: "#111827"
    signal closeRequested()

    // Left edge border
    Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: "#1E94A3B8" }

    ListModel {
        id: chatModel
        ListElement { role: "ai"; text: "Hello! I'm Aurion AI. Ask me about your hardware, system issues, or settings.\n\nTry: \"Check my hardware\" or \"Why is my WiFi slow?\"" }
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 44; color: "transparent"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 10; spacing: 8
                Text { text: "✦"; font.pixelSize: 16; color: "#6366F1" }
                Text { text: "Aurion AI"; font.family: "Inter"; font.pixelSize: 15; font.weight: Font.DemiBold; color: "#F1F5F9" }
                Rectangle { width: 6; height: 6; radius: 3; color: "#10B981" }
                Text { text: "Ready"; font.family: "Inter"; font.pixelSize: 11; color: "#94A3B8" }
                Item { Layout.fillWidth: true }
                Text {
                    text: "✕"; font.pixelSize: 16; color: "#94A3B8"
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sidebar.closeRequested()
                    }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1E94A3B8" }
        }

        // Quick action chips
        Flow {
            Layout.fillWidth: true; Layout.margins: 10; spacing: 6
            Repeater {
                model: ["Check hardware", "Recent errors", "System info"]
                delegate: Rectangle {
                    width: ct.width + 16; height: 26; radius: 6
                    color: cma.containsMouse ? "#1E293B" : "transparent"
                    border.color: "#1E94A3B8"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text { id: ct; anchors.centerIn: parent; text: modelData; font.family: "Inter"; font.pixelSize: 11; color: "#94A3B8" }
                    MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sendMsg(modelData) }
                }
            }
        }

        // Chat messages
        ListView {
            id: chatView
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.leftMargin: 10; Layout.rightMargin: 10
            model: chatModel; clip: true; spacing: 10

            delegate: Item {
                width: chatView.width; height: bubble.height + 4
                Rectangle {
                    id: bubble
                    width: Math.min(msgTxt.implicitWidth + 24, chatView.width * 0.88)
                    height: msgTxt.implicitHeight + 18
                    radius: 12
                    color: model.role === "user" ? "#6366F1" : "#1E293B"
                    anchors.right: model.role === "user" ? parent.right : undefined
                    anchors.left: model.role === "ai" ? parent.left : undefined

                    Text {
                        id: msgTxt; anchors.fill: parent; anchors.margins: 10
                        text: model.text; wrapMode: Text.WordWrap
                        font.family: model.role === "ai" ? "Inter" : "Inter"
                        font.pixelSize: 13; color: "#F1F5F9"; lineHeight: 1.4
                    }
                }
            }

            onCountChanged: Qt.callLater(function() { chatView.positionViewAtEnd() })
        }

        // Input
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50; color: "#1E293B"
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#1E94A3B8" }
            RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 6
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 8; color: "#111827"
                    TextInput {
                        id: msgInput; anchors.fill: parent; anchors.margins: 10
                        font.family: "Inter"; font.pixelSize: 13; color: "#F1F5F9"
                        clip: true; verticalAlignment: TextInput.AlignVCenter
                        Text { visible: !msgInput.text; text: "Ask Aurion AI..."; font: msgInput.font; color: "#64748B" }
                        Keys.onReturnPressed: sendMsg(msgInput.text)
                    }
                }
                Rectangle {
                    width: 34; height: 34; radius: 8
                    color: msgInput.text.length > 0 ? "#6366F1" : "#1E293B"
                    Text { anchors.centerIn: parent; text: "→"; font.pixelSize: 16; color: msgInput.text.length > 0 ? "#FFF" : "#64748B" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sendMsg(msgInput.text) }
                }
            }
        }
    }

    function sendMsg(text) {
        var msg = text.trim()
        if (!msg) return
        chatModel.append({ role: "user", text: msg })
        msgInput.text = ""
        // Call AI service
        dbusClient.askAI(msg, "shell-sidebar")
    }

    // Receive AI responses
    Connections {
        target: dbusClient
        function onAiResponseReceived(response) {
            chatModel.append({ role: "ai", text: response })
        }
    }
}
