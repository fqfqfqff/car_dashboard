QT += quick qml gui svg quickeffects bluetooth

CONFIG += c++17

TARGET = CarDashboard
TEMPLATE = app

SOURCES += \
    main.cpp \
    backend/DataModel.cpp \
    backend/Controller.cpp \
    backend/Simulator.cpp \
    ui/GaugeItem.cpp \
    ui/CANReader.cpp

HEADERS += \
    backend/DataModel.h \
    backend/Controller.h \
    backend/Simulator.h \
    ui/GaugeItem.h \
    ui/CANReader.h

RESOURCES += resources.qrc

android {
    ANDROID_ABIS = arm64-v8a
    ANDROID_MIN_SDK_VERSION = 29
    ANDROID_TARGET_SDK_VERSION = 34
    ANDROID_VERSION_CODE = 1
    ANDROID_VERSION_NAME = 1.0.0
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
}

QMAKE_APPLE_DEVICE_ARCHS = arm64

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
