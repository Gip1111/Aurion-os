// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Launcher — MVP
// Full-screen overlay, type-to-search, Escape to dismiss.

import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: launcher
    color: "#D8080C16"
    signal dismissed()

    // Click background to dismiss
    MouseArea { anchors.fill: parent; onClicked: launcher.dismissed() }

    // Stub app database
    property var appDb: [
        { name: "Files",         icon: "📁", desc: "File manager",      cmd: "thunar" },
        { name: "Terminal",      icon: "🖥", desc: "System terminal",   cmd: "foot" },
        { name: "Firefox",       icon: "🌐", desc: "Web browser",       cmd: "firefox" },
        { name: "Text Editor",   icon: "📝", desc: "Plain text editor", cmd: "mousepad" },
        { name: "System Monitor",icon: "📊", desc: "Resource monitor",  cmd: "htop" },
        { name: "Settings",      icon: "⚙", desc: "System settings",   cmd: "" },
        { name: "AI Assistant",  icon: "✦", desc: "Open AI sidebar",   cmd: "__ai__" },
        { name: "Hardware",      icon: "🔧", desc: "Hardware status",   cmd: "" },
    ]

    ListModel { id: results }

    Column {
        anchors.centerIn: parent; anchors.verticalCenterOffset: -60
        width: 560; spacing: 12

        // Search bar
        Rectangle {
            width: parent.width; height: 52; radius: 14
            color: "#1E293B"
            border.color: searchInput.activeFocus ? "#6366F1" : "#1E94A3B8"
            border.width: searchInput.activeFocus ? 2 : 1

            Row {
                anchors.fill: parent; anchors.margins: 14; spacing: 10
                Text { text: "🔍"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                TextInput {
                    id: searchInput
                    width: parent.width - 36
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Inter"; font.pixelSize: 16
                    color: "#F1F5F9"; selectionColor: "#6366F1"; clip: true
                    focus: launcher.visible

                    Text {
                        visible: !searchInput.text
                        text: "Search apps, files, actions..."
                        font: searchInput.font; color: "#64748B"
                    }

                    onTextChanged: doSearch(text)
                    Keys.onEscapePressed: launcher.dismissed()
                    Keys.onReturnPressed: if (results.count > 0) activate(0)
                    Keys.onDownPressed: resultsList.incrementCurrentIndex()
                    Keys.onUpPressed: resultsList.decrementCurrentIndex()
                }
            }
        }

        // Results
        ListView {
            id: resultsList
            width: parent.width; height: Math.min(results.count * 50, 350)
            model: results; clip: true; visible: results.count > 0
            currentIndex: 0
            highlight: Rectangle { color: "#1E293B"; radius: 8 }
            highlightMoveDuration: 80

            delegate: Item {
                width: resultsList.width; height: 50
                Row {
                    anchors.fill: parent; anchors.margins: 8; spacing: 10
                    Rectangle {
                        width: 34; height: 34; radius: 6; color: "#1E293B"
                        anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: model.icon; font.pixelSize: 16 }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 1
                        Text { text: model.name; font.family: "Inter"; font.pixelSize: 14; color: "#F1F5F9" }
                        Text { text: model.desc; font.family: "Inter"; font.pixelSize: 11; color: "#94A3B8" }
                    }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: activate(index)
                }
            }
        }

        // Hint
        Text {
            visible: results.count === 0 && searchInput.text === ""
            text: "Type to search · Esc to close · ↑↓ to navigate · Enter to launch"
            font.family: "Inter"; font.pixelSize: 11; color: "#64748B"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    function doSearch(query) {
        results.clear()
        if (query.length === 0) {
            // Show all apps when empty
            for (var i = 0; i < appDb.length; i++)
                results.append(appDb[i])
            return
        }
        var q = query.toLowerCase()
        for (var j = 0; j < appDb.length; j++) {
            var app = appDb[j]
            if (app.name.toLowerCase().indexOf(q) >= 0 || app.desc.toLowerCase().indexOf(q) >= 0)
                results.append(app)
        }
    }

    function activate(idx) {
        var item = results.get(idx)
        if (item.cmd === "__ai__") {
            shellController.toggleAiSidebar()
        } else if (item.cmd) {
            console.log("[launcher] exec:", item.cmd)
            // TODO: QProcess launch from C++
        }
        launcher.dismissed()
    }

    onVisibleChanged: {
        if (visible) { searchInput.text = ""; searchInput.forceActiveFocus(); doSearch("") }
    }
}
