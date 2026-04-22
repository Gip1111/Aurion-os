// AurionOS Calamares Slideshow
// Shown during installation progress.

import QtQuick 2.15

Rectangle {
    id: root
    width: 800; height: 440
    color: "#0A0E1A"

    property int currentSlide: 0
    property var slides: [
        { title: "Welcome to AurionOS", desc: "A next-generation operating system designed around you." },
        { title: "AI-Powered Assistance", desc: "Ask Aurion AI about your hardware, fix problems, and understand your system." },
        { title: "Hardware Intelligence", desc: "AurionOS scans your hardware automatically and tells you what's working." },
        { title: "Safe by Design", desc: "Btrfs snapshots protect your system. Every change is reversible." },
        { title: "Almost Ready", desc: "Your AurionOS installation is being set up..." },
    ]

    Column {
        anchors.centerIn: parent; spacing: 20; width: 600

        Text {
            text: slides[currentSlide].title
            font.family: "Inter"; font.pixelSize: 28; font.weight: Font.DemiBold
            color: "#F1F5F9"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: slides[currentSlide].desc
            font.family: "Inter"; font.pixelSize: 16
            color: "#94A3B8"; wrapMode: Text.WordWrap
            width: parent.width; horizontalAlignment: Text.AlignHCenter
        }

        // Slide indicator dots
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
            Repeater {
                model: slides.length
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: index === currentSlide ? "#6366F1" : "#1E293B"
                }
            }
        }
    }

    Timer {
        interval: 6000; running: true; repeat: true
        onTriggered: currentSlide = (currentSlide + 1) % slides.length
    }
}
