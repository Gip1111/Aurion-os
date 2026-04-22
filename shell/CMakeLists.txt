cmake_minimum_required(VERSION 3.20)
project(aurion-shell VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# --- Dependencies ---
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Quick
    Gui
    WaylandClient
    DBus
)

# layer-shell-qt: try pkg-config first, then cmake
find_package(PkgConfig)
if(PkgConfig_FOUND)
    pkg_check_modules(LAYER_SHELL layershell-qt6)
endif()
if(NOT LAYER_SHELL_FOUND)
    find_package(LayerShellQt QUIET)
    if(LayerShellQt_FOUND)
        set(LAYER_SHELL_FOUND TRUE)
        set(LAYER_SHELL_LIBRARIES LayerShellQt::Interface)
    endif()
endif()

if(LAYER_SHELL_FOUND)
    add_definitions(-DHAVE_LAYER_SHELL)
    message(STATUS "layer-shell-qt found — layer-shell surfaces enabled")
else()
    message(WARNING "layer-shell-qt NOT found — shell will use regular windows (dev mode)")
endif()

# --- Sources ---
set(SOURCES
    src/main.cpp
    src/shellcontroller.cpp
    src/shellcontroller.h
    src/dbusclient.cpp
    src/dbusclient.h
    src/shelladaptor.cpp
    src/shelladaptor.h
)

qt6_add_resources(QML_RESOURCES src/qml/qml.qrc)

add_executable(aurion-shell ${SOURCES} ${QML_RESOURCES})

target_link_libraries(aurion-shell PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Gui
    Qt6::WaylandClient
    Qt6::DBus
)

if(LAYER_SHELL_FOUND)
    target_link_libraries(aurion-shell PRIVATE ${LAYER_SHELL_LIBRARIES})
    if(LAYER_SHELL_INCLUDE_DIRS)
        target_include_directories(aurion-shell PRIVATE ${LAYER_SHELL_INCLUDE_DIRS})
    endif()
endif()

# --- Install ---
install(TARGETS aurion-shell DESTINATION bin)
