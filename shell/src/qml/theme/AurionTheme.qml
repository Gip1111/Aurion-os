// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Shell — Theme Singleton
// Provides design tokens to all QML components.

pragma Singleton
import QtQuick

QtObject {
    // --- Colors (Dark Theme) ---
    readonly property color bgDeep: "#0A0E1A"
    readonly property color bgBase: "#111827"
    readonly property color bgElevated: "#1E293B"
    readonly property color bgOverlay: Qt.rgba(0.067, 0.094, 0.153, 0.85)

    readonly property color fgPrimary: "#F1F5F9"
    readonly property color fgSecondary: "#94A3B8"
    readonly property color fgMuted: "#64748B"

    readonly property color accentPrimary: "#6366F1"
    readonly property color accentHover: "#818CF8"
    readonly property color accentGlow: Qt.rgba(0.388, 0.4, 0.945, 0.25)
    readonly property color accentWarm: "#F59E0B"
    readonly property color accentSuccess: "#10B981"
    readonly property color accentDanger: "#EF4444"

    readonly property color glassBg: Qt.rgba(0.067, 0.094, 0.153, 0.65)
    readonly property color glassBorder: Qt.rgba(0.58, 0.64, 0.72, 0.12)
    readonly property real glassBlur: 24

    readonly property color statusOk: "#10B981"
    readonly property color statusWarn: "#F59E0B"
    readonly property color statusError: "#EF4444"
    readonly property color statusUnknown: "#64748B"

    // --- Typography ---
    readonly property string fontPrimary: "Inter"
    readonly property string fontMono: "JetBrains Mono"
    readonly property string fontDisplay: "Outfit"

    readonly property int bodyMdSize: 13
    readonly property int bodyLgSize: 15
    readonly property int bodySm: 11
    readonly property int headingMd: 18
    readonly property int headingLg: 24
    readonly property int displayLg: 32

    // --- Spacing ---
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24
    readonly property int spacing2xl: 32

    // --- Radius ---
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 16
    readonly property int radiusXl: 24

    // --- Animation ---
    readonly property int animFast: 120
    readonly property int animNormal: 200
    readonly property int animSlow: 350
    readonly property int animPage: 500

    // --- Easing ---
    readonly property var easingDefault: Easing.OutCubic
    readonly property var easingSpring: Easing.OutBack
}
