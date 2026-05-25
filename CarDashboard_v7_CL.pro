QT += quick qml gui svg quickeffects network

CONFIG += c++17

TARGET   = CarDashboard
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

# ─── Kvaser CANlib (Windows, MinGW 64-bit) ────────────────────────────────────
#
# Проблема: Kvaser поставляет canlib32.lib в формате MSVC.
# MinGW не может линковать .lib напрямую через -lcanlib32.
# Решение: используем прямое указание полного пути к .lib файлу.
#
# ВАЖНО: Для MinGW необходимо либо:
#   (A) Использовать полный путь к .lib (работает с новыми версиями MinGW ld)
#   (B) Конвертировать .lib в .a командой: dlltool -d canlib32.def -l libcanlib32.a
#       (def-файл можно сгенерировать из dll: gendef canlib32.dll)
#
win32 {
    KVASER_PATH = "C:/Program Files (x86)/Kvaser/Canlib"

    INCLUDEPATH += $$KVASER_PATH/INC

    LIBS += -L"C:/Program Files (x86)/Kvaser/Canlib/Lib/x64" -lcanlib32
}

# ─── macOS/Linux (заглушка, для сборки без железа) ───────────────────────────
macx|unix {
    message("CANlib stub mode: сборка без Kvaser")
}

QMAKE_APPLE_DEVICE_ARCHS = arm64

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
