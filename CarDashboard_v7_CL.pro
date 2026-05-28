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

    # CAN включается только если драйвер Kvaser реально установлен.
    exists("$$KVASER_PATH/INC/canlib.h") {
        message("Kvaser CANlib найден — сборка С поддержкой CAN")
        DEFINES     += HAVE_CANLIB
        INCLUDEPATH += $$KVASER_PATH/INC
        LIBS        += -L"$$KVASER_PATH/Lib/x64" -lcanlib32
    } else {
        message("Kvaser CANlib не найден — сборка БЕЗ CAN (заглушка)")
    }
}

# ─── macOS / Linux — всегда без CAN (Kvaser только под Windows) ───────────────
# HAVE_CANLIB не определяется → CANReader использует заглушку, работает симулятор.
macx|unix:!android {
    message("Платформа без Kvaser — сборка БЕЗ CAN (заглушка)")
}

# Архитектуру под macOS определяет выбранный Qt-кит (arm64 или x86_64) —
# жёстко не фиксируем, чтобы собиралось и на Apple Silicon, и на Intel.

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
