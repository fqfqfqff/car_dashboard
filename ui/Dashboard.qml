// =============================================================================
// Dashboard.qml — Главный layout. Переработка v6.
//
// ИЗМЕНЕНИЯ v6:
//   • Реалистичный self-check при запуске:
//     1. engineRunning → фаза "sweep": все индикаторы загораются (2 сек)
//     2. Через 2 сек → фаза "normal": гасятся индикаторы без ошибок
//   • Двигатель выключен → фаза "idle": ВСЕ индикаторы погашены
//   • Ручник остаётся включённым независимо от фазы (brakeSystem)
//   • Мигание централизовано в CriticalStrip._blinkOn (не индивидуальные таймеры)
//   • Race condition устранён: opacity = _fadeOp * _blinkMul
// =============================================================================

import QtQuick 2.15

Item {
    id: root
    anchors.fill: parent

    // Фазы:
    //   "idle"   — двигатель выключен
    //   "sweep"  — self-check (все индикаторы горят, 2 сек)
    //   "normal" — нормальная работа (только ошибки)
    property string startupPhase:     "idle"
    property real   centerUIOpacity:  0.0

    property real centerWidthRatio:   0.29
    property real centerHeightRatio:  0.9

    readonly property real gaugeSize: Math.min(root.height * 0.62, root.width * 0.36)
    readonly property real rpmNorm:   Math.min(1.0, dataModel.rpm / 8000.0)

    // ── ЗАПУСК / ОСТАНОВКА ──────────────────────────────────────────────────
    Connections {
        target: dataModel
        function onEngineRunningChanged() {
            if (dataModel.engineRunning) {
                // Запуск: начинаем self-check
                root.startupPhase    = "sweep"
                root.centerUIOpacity = 0.0
                speedGauge.startSweep()
                rpmGauge.startSweep()
                centerFadeIn.start()
                selfCheckTimer.restart()
            } else {
                // Остановка: всё гасим
                selfCheckTimer.stop()
                centerFadeIn.stop()
                root.startupPhase    = "idle"
                root.centerUIOpacity = 0.0
            }
        }
    }

    // Self-check длится 3.5 сек (sweep = 3 сек), затем переходим в "normal"
    Timer {
        id: selfCheckTimer
        interval: 3500
        repeat:   false
        onTriggered: {
            if (root.startupPhase === "sweep") {
                root.startupPhase = "normal"
            }
        }
    }

    NumberAnimation {
        id: centerFadeIn
        target:      root
        property:    "centerUIOpacity"
        from:        0.0
        to:          1.0
        duration:    650
        easing.type: Easing.InOutQuad
        running: false
    }

    // ── ФОН ──────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#090910"
    }

    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            var v = ctx.createRadialGradient(
                width/2, height/2, height * 0.18,
                width/2, height/2, height * 0.72
            )
            v.addColorStop(0.0, "rgba(0,0,0,0.00)")
            v.addColorStop(1.0, "rgba(0,0,0,0.1)")
            ctx.fillStyle = v
            ctx.fillRect(0, 0, width, height)
        }
    }

    Rectangle {
        anchors.centerIn: speedGauge
        width: speedGauge.width * 0.96; height: speedGauge.height * 0.96
        radius: width/2; color: "#000000"; opacity: 0.25
        visible: !speedGauge.sweeping
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    Rectangle {
        anchors.centerIn: rpmGauge
        width: rpmGauge.width * 0.96; height: rpmGauge.height * 0.96
        radius: width/2; color: "#000000"; opacity: 0.25
        visible: !rpmGauge.sweeping
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    Rectangle {
        anchors.fill: contentCenter; anchors.margins: -10
        color: "#000000"; opacity: 0.15; radius: 12
        visible: root.startupPhase !== "idle"
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // ── СПИДОМЕТР ─────────────────────────────────────────────────────────────
    Gauge {
        id: speedGauge
        anchors.left:                 parent.left
        anchors.leftMargin:           root.width * 0.006
        anchors.verticalCenter:       parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.025
        width:  root.gaugeSize; height: root.gaugeSize
        minValue: 0; maxValue: 300; step: 20; unit: "km/h"
        arcColor: "#FF3B30"; dangerZone: 0.85
        value: dataModel.speed; centerText: ""
        glowIntensity: root.rpmNorm * 2
    }

    // ── ТАХОМЕТР ──────────────────────────────────────────────────────────────
    Gauge {
        id: rpmGauge
        anchors.right:                parent.right
        anchors.rightMargin:          root.width * 0.006
        anchors.verticalCenter:       parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.025
        width:  root.gaugeSize; height: root.gaugeSize
        minValue: 0; maxValue: 8000; step: 1000; unit: ""
        arcColor: "#FF3B30"; dangerZone: 0.80
        value: dataModel.rpm; glowIntensity: root.rpmNorm
        centerText: {
            if (!dataModel.engineRunning) return "P"
            if (dataModel.canConnected && dataModel.currentGear === 0) return ""
            if (dataModel.currentGear === 0) return "N"
            return dataModel.currentGear.toString()
        }
    }

    // ── ЦЕНТРАЛЬНАЯ ЗОНА ──────────────────────────────────────────────────────
    Item {
        id: contentCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.2
        width:  parent.width  * root.centerWidthRatio
        height: parent.height * root.centerHeightRatio
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity

        IndicatorPanel {
            id: indicatorPanel
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: parent.height * 0.40
        }

        Display {
            id: centerDisplay
            anchors.top: indicatorPanel.bottom; anchors.topMargin: root.height * 0.01
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            criticalLabels: indicatorPanel.activeCriticalLabels
            hasCritical: indicatorPanel.anyCritical
        }
    }

    // ── ПАНЕЛЬ УПРАВЛЕНИЯ ─────────────────────────────────────────────────────
    ControlsOverlay {
        id: controlsOverlay
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.006
        width: root.width * 0.92
        height: root.height * 0.140
    }

    // ── ПОЛОСЫ ИНДИКАТОРОВ ────────────────────────────────────────────────────
    // Красные (critical) – над центральной панелью
    CriticalStrip {
        id: criticalStrip
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: centerDisplay.top
            bottomMargin: root.height * 0.02
        }
        width: parent.width * 0.85
        iconSz: 56
        startupMode:   root.startupPhase === "sweep"
        engineRunning: dataModel.engineRunning
        systemActive:  root.startupPhase !== "idle"
    }

    // Жёлтые (warning) – под центральной панелью
    WarningStrip {
        id: warningStrip
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: centerDisplay.bottom
            topMargin: root.height * 0.02
            bottom: controlsOverlay.top
            bottomMargin: root.height * 0.02
        }
        width: parent.width * 0.85
        iconSz: 52
        startupMode:   root.startupPhase === "sweep"
        engineRunning: dataModel.engineRunning
        systemActive:  root.startupPhase !== "idle"
    }
}
