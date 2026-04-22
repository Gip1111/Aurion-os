// SPDX-License-Identifier: GPL-3.0-or-later
// AurionOS Shell — Main entry point (MVP)
//
// Initializes layer-shell (if available), registers on D-Bus,
// and loads the QML shell UI.

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDBusConnection>
#include <QDBusError>
#include <QDebug>
#include <QScreen>

#ifdef HAVE_LAYER_SHELL
#include <LayerShellQt/Shell>
#endif

#include "shellcontroller.h"
#include "dbusclient.h"
#include "shelladaptor.h"

int main(int argc, char *argv[])
{
#ifdef HAVE_LAYER_SHELL
    // Must be called before QGuiApplication construction
    LayerShellQt::Shell::useLayerShell();
    qDebug() << "[aurion-shell] Layer-shell mode enabled";
#else
    qDebug() << "[aurion-shell] Running in dev mode (no layer-shell)";
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName("aurion-shell");
    app.setApplicationVersion("0.1.0");
    app.setOrganizationName("AurionOS");
    app.setDesktopFileName("aurion-shell");

    // --- Shell Controller ---
    ShellController controller;

    // --- D-Bus Registration ---
    // Register the shell on the session bus so labwc keybindings
    // can call ToggleLauncher / ToggleAISidebar via dbus-send.
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    new ShellAdaptor(&controller);

    if (!sessionBus.registerService("org.aurion.Shell")) {
        qWarning() << "[aurion-shell] Failed to register D-Bus service:"
                    << sessionBus.lastError().message();
        // Continue anyway — shell still works, just no keybinding support
    }
    if (!sessionBus.registerObject("/org/aurion/Shell", &controller)) {
        qWarning() << "[aurion-shell] Failed to register D-Bus object";
    } else {
        qDebug() << "[aurion-shell] D-Bus service registered: org.aurion.Shell";
    }

    // --- D-Bus Client (to system services) ---
    DBusClient dbusClient;

    // --- Screen info for QML ---
    QScreen *primaryScreen = app.primaryScreen();
    int screenWidth = primaryScreen ? primaryScreen->size().width() : 1920;
    int screenHeight = primaryScreen ? primaryScreen->size().height() : 1080;

    // --- QML Engine ---
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("shellController", &controller);
    engine.rootContext()->setContextProperty("dbusClient", &dbusClient);
    engine.rootContext()->setContextProperty("screenWidth", screenWidth);
    engine.rootContext()->setContextProperty("screenHeight", screenHeight);
    engine.rootContext()->setContextProperty("hasLayerShell",
#ifdef HAVE_LAYER_SHELL
        true
#else
        false
#endif
    );

    engine.addImportPath("qrc:/qml");
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "[aurion-shell] Failed to load QML";
        return -1;
    }

    qDebug() << "[aurion-shell] Shell started successfully";
    qDebug() << "[aurion-shell] Shortcuts: Super+Space=Launcher, Super+A=AI Sidebar";

    return app.exec();
}
