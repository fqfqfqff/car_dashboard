import QtQuick 2.15

Item {
    id: root
    anchors.fill: parent

    property string startupPhase:    "idle"
    property real   centerUIOpacity: 0.0

    // ── ЕДИНАЯ СИСТЕМА КООРДИНАТ ──────────────────────────────────────────────
    readonly property real gaugeSize: Math.min(root.height * 0.60, root.width * 0.34)
    readonly property real gaugeCY:   root.height * 0.44
    readonly property real gaugeMarH: root.width  * 0.010

    // Внутренние края гаджей
    readonly property real speedInnerX: gaugeMarH + gaugeSize
    readonly property real rpmInnerX:   root.width - gaugeMarH - gaugeSize

    // Радиус гаджа (половина размера)
    readonly property real gaugeR: gaugeSize / 2

    // Верх/низ гаджей — дисплей СТРОГО внутри этих границ
    readonly property real gaugeTop:    gaugeCY - gaugeR
    readonly property real gaugeBottom: gaugeCY + gaugeR

    // Дисплей: от верха до низа гаджей, заходит под них по бокам
    readonly property real displayOverlap: gaugeSize * 0.10
    readonly property real displayX: speedInnerX - displayOverlap
    readonly property real displayW: rpmInnerX - speedInnerX + displayOverlap * 2

    // Дисплей чуть уже гаджей по высоте — не выступает
    readonly property real displayPadV: gaugeSize * 0.06
    readonly property real displayY: gaugeTop    + displayPadV
    readonly property real displayH: gaugeBottom - gaugeTop - displayPadV * 2

    // Зона для индикаторов/стрипов — СТРОГО внутри контура кластера
    // (между верхом гаджей и верхом дисплея)
    readonly property real stripZoneTop:    gaugeTop + gaugeSize * 0.04
    readonly property real stripZoneBottom: displayY - root.height * 0.006
    readonly property real stripW:          rpmInnerX - speedInnerX - gaugeSize * 0.08

    // Зона для WarningStrip — между низом дисплея и низом гаджей
    readonly property real warnZoneTop:    displayY + displayH + root.height * 0.006
    readonly property real warnZoneBottom: gaugeBottom - gaugeSize * 0.04

    readonly property real rpmNorm: Math.min(1.0, dataModel.rpm / 8000.0)

    Connections {
        target: dataModel
        function onEngineRunningChanged() {
            if (dataModel.engineRunning) {
                root.startupPhase    = "sweep"
                root.centerUIOpacity = 0.0
                speedGauge.startSweep()
                rpmGauge.startSweep()
                centerFadeIn.start()
                selfCheckTimer.restart()
            } else {
                selfCheckTimer.stop()
                centerFadeIn.stop()
                root.startupPhase    = "idle"
                root.centerUIOpacity = 0.0
            }
        }
    }

    Timer {
        id: selfCheckTimer
        interval: 3500; repeat: false
        onTriggered: { if (root.startupPhase === "sweep") root.startupPhase = "normal" }
    }

    NumberAnimation {
        id: centerFadeIn
        target: root; property: "centerUIOpacity"
        from: 0.0; to: 1.0; duration: 650
        easing.type: Easing.InOutQuad; running: false
    }

    // ── z=0: ФОН ─────────────────────────────────────────────────────────────
    Rectangle { anchors.fill: parent; color: "#090910"; z: 0 }

    Canvas {
        anchors.fill: parent; z: 0
        onPaint: {
            var ctx = getContext("2d")
            var g = ctx.createRadialGradient(
                width/2, root.gaugeCY, height*0.12,
                width/2, root.gaugeCY, height*0.68
            )
            g.addColorStop(0.0, "rgba(0,0,0,0.00)")
            g.addColorStop(1.0, "rgba(0,0,0,0.12)")
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
        }
    }

    // ── z=1: ДИСПЛЕЙ + ИНДИКАТОРЫ (внутри кластера) ──────────────────────────

    // Критические — строго между верхом кластера и верхом дисплея
    CriticalStrip {
        id: criticalStrip
        x:      root.speedInnerX + (root.rpmInnerX - root.speedInnerX - root.stripW) / 2
        y:      root.stripZoneTop
        width:  root.stripW
        height: Math.max(0, root.stripZoneBottom - root.stripZoneTop)
        iconSz: Math.min(38, height * 0.80)
        startupMode:   root.startupPhase === "sweep"
        engineRunning: dataModel.engineRunning
        systemActive:  root.startupPhase !== "idle"
        z: 1
        clip: true
    }

    // Дисплей — строго внутри вертикальных границ гаджей
    Display {
        id: centerDisplay
        x:      root.displayX
        y:      root.displayY
        width:  root.displayW
        height: root.displayH
        sideOverlap: root.displayOverlap
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity
        z: 1
        criticalLabels: indicatorPanel.activeCriticalLabels
        hasCritical:    indicatorPanel.anyCritical
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // IndicatorPanel — между дисплеем и его верхней частью (внутри Display)
    // Вынесен в отдельный элемент только если нужен снаружи Display
    IndicatorPanel {
        id: indicatorPanel
        x:      root.speedInnerX + root.gaugeSize * 0.04
        y:      root.stripZoneBottom - height
        width:  root.stripW
        height: Math.min(root.height * 0.08, root.stripZoneBottom - root.stripZoneTop)
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity
        z: 1
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // Предупреждения — между низом дисплея и низом кластера
    WarningStrip {
        id: warningStrip
        x:      root.speedInnerX + (root.rpmInnerX - root.speedInnerX - root.stripW) / 2
        y:      root.warnZoneTop
        width:  root.stripW
        height: Math.max(0, root.warnZoneBottom - root.warnZoneTop)
        iconSz: Math.min(36, height * 0.80)
        startupMode:   root.startupPhase === "sweep"
        engineRunning: dataModel.engineRunning
        systemActive:  root.startupPhase !== "idle"
        z: 1
        clip: true
    }

    // ── z=2: КОНТУР КЛАСТЕРА ─────────────────────────────────────────────────
    PanelOutline {
        anchors.fill: parent
        z: 2
    }

    // ── z=3: ГАДЖИ ───────────────────────────────────────────────────────────
    Gauge {
        id: speedGauge
        x:      root.gaugeMarH
        y:      root.gaugeCY - root.gaugeR
        width:  root.gaugeSize
        height: root.gaugeSize
        minValue: 0; maxValue: 300; step: 20; unit: "km/h"
        arcColor: "#FF3B30"; dangerZone: 0.85
        value: dataModel.speed; centerText: ""
        glowIntensity: root.rpmNorm * 2
        z: 3
    }

    Gauge {
        id: rpmGauge
        x:      root.width - root.gaugeMarH - root.gaugeSize
        y:      root.gaugeCY - root.gaugeR
        width:  root.gaugeSize
        height: root.gaugeSize
        minValue: 0; maxValue: 8000; step: 1000; unit: ""
        arcColor: "#FF3B30"; dangerZone: 0.80
        value: dataModel.rpm; glowIntensity: root.rpmNorm
        centerText: {
            if (!dataModel.engineRunning) return "P"
            if (dataModel.currentGear === 0) return "N"
            return dataModel.currentGear.toString()
        }
        z: 3
    }

    // ── z=0: ПАНЕЛЬ УПРАВЛЕНИЯ ───────────────────────────────────────────────
    ControlsOverlay {
        id: controlsOverlay
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     root.height * 0.008
        width:  root.width  * 0.92
        height: root.height * 0.138
        z: 0
    }
}
