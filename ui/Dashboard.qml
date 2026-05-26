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
    readonly property real gaugeR:    gaugeSize / 2

    // Внутренние края гаджей (правая сторона спидометра / левая сторона тахометра)
    readonly property real speedInnerX: gaugeMarH + gaugeSize
    readonly property real rpmInnerX:   root.width - gaugeMarH - gaugeSize
    readonly property real gaugeTop:    gaugeCY - gaugeR
    readonly property real gaugeBottom: gaugeCY + gaugeR

    // Центральная панель:
    // — X начинается точно на внутреннем крае спидометра (без overlap!)
    // — боковые дуги Display строятся по той же окружности что и гаджи,
    //   поэтому стык визуально идеальный
    readonly property real displayOverlap: gaugeR * 0.18   // только для Canvas-дуг внутри Display
    readonly property real displayX: speedInnerX
    readonly property real displayW: rpmInnerX - speedInnerX

    // Высота: меньше гаджей на displayPadV с каждой стороны
    readonly property real displayPadV: gaugeSize * 0.085
    readonly property real displayY: gaugeTop    + displayPadV
    readonly property real displayH: gaugeBottom - gaugeTop - displayPadV * 2

    // Стрипы между верхом гаджей и Display
    readonly property real stripZoneTop:    gaugeTop + gaugeSize * 0.04
    readonly property real stripZoneBottom: displayY - root.height * 0.005
    readonly property real stripW:          rpmInnerX - speedInnerX - gaugeSize * 0.06

    readonly property real warnZoneTop:    displayY + displayH + root.height * 0.005
    readonly property real warnZoneBottom: gaugeBottom - gaugeSize * 0.04

    // RPM-свечение — сглаженное
    readonly property real rpmNorm: Math.min(1.0, dataModel.rpm / 8000.0)
    property real _smoothRpmNorm: 0.0
    Behavior on _smoothRpmNorm {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }
    onRpmNormChanged: _smoothRpmNorm = rpmNorm

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
        from: 0.0; to: 1.0; duration: 900
        easing.type: Easing.InOutQuad; running: false
    }

    // ── z=0: ФОН ─────────────────────────────────────────────────────────────
    Rectangle { anchors.fill: parent; color: "#07080D"; z: 0 }

    Canvas {
        anchors.fill: parent; z: 0
        onPaint: {
            var ctx = getContext("2d")
            var g = ctx.createRadialGradient(width/2, height*0.5, 0, width/2, height*0.5, width*0.62)
            g.addColorStop(0.0,  "rgba(0,0,0,0.00)")
            g.addColorStop(0.75, "rgba(0,0,0,0.08)")
            g.addColorStop(1.0,  "rgba(0,0,0,0.30)")
            ctx.fillStyle = g; ctx.fillRect(0, 0, width, height)
        }
    }

    // ── z=1: СТРИПЫ ──────────────────────────────────────────────────────────
    CriticalStrip {
        x:      root.speedInnerX + (root.rpmInnerX - root.speedInnerX - root.stripW) / 2
        y:      root.stripZoneTop
        width:  root.stripW
        height: Math.max(0, root.stripZoneBottom - root.stripZoneTop)
        iconSz: Math.min(38, height * 0.80)
        startupMode:   root.startupPhase === "sweep"
        engineRunning: dataModel.engineRunning
        systemActive:  root.startupPhase !== "idle"
        z: 1; clip: true
    }

    WarningStrip {
        x:      root.speedInnerX + (root.rpmInnerX - root.speedInnerX - root.stripW) / 2
        y:      root.warnZoneTop
        width:  root.stripW
        height: Math.max(0, root.warnZoneBottom - root.warnZoneTop)
        iconSz: Math.min(36, height * 0.80)
        startupMode:   root.startupPhase === "sweep"
        engineRunning: dataModel.engineRunning
        systemActive:  root.startupPhase !== "idle"
        z: 1; clip: true
    }

    // ── z=2: КОНТУР КЛАСТЕРА ─────────────────────────────────────────────────
    PanelOutline { anchors.fill: parent; z: 2 }

    // ── z=3: ЦЕНТРАЛЬНАЯ ПАНЕЛЬ — под гаджами ────────────────────────────────
    // Display НЕ заходит под гаджи (displayX = speedInnerX точно).
    // Боковые дуги внутри Display строятся по gaugeR — визуально стыкуются.
    Display {
        id: centerDisplay
        x:      root.displayX
        y:      root.displayY
        width:  root.displayW
        height: root.displayH
        sideOverlap: root.displayOverlap   // передаём для рисования дуг внутри Canvas
        gaugeR:      root.gaugeR
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity
        z: 3
        criticalLabels: indicatorPanel.activeCriticalLabels
        hasCritical:    indicatorPanel.anyCritical
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    }

    // ── z=3: ИНДИКАТОРНАЯ ПАНЕЛЬ ─────────────────────────────────────────────
    IndicatorPanel {
        id: indicatorPanel
        x:      root.speedInnerX + root.gaugeSize * 0.04
        y:      root.stripZoneBottom - height
        width:  root.stripW
        height: Math.min(root.height * 0.08, root.stripZoneBottom - root.stripZoneTop)
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity
        z: 3
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    }

    // ── z=5: ГАДЖИ — самый верхний слой, перекрывают всё ────────────────────
    // clip:true обрезает правый край спидометра / левый край тахометра
    // так что их прямоугольные Item не торчат поверх Display
    Gauge {
        id: speedGauge
        x: root.gaugeMarH;  y: root.gaugeCY - root.gaugeR
        width: root.gaugeSize; height: root.gaugeSize
        clip: true
        minValue: 0; maxValue: 300; step: 20; unit: "km/h"
        arcColor: "#FF3B30"; dangerZone: 0.85
        value: dataModel.speed; centerText: ""
        glowIntensity: root._smoothRpmNorm * 2
        z: 5
    }

    Gauge {
        id: rpmGauge
        x: root.width - root.gaugeMarH - root.gaugeSize; y: root.gaugeCY - root.gaugeR
        width: root.gaugeSize; height: root.gaugeSize
        clip: true
        minValue: 0; maxValue: 8000; step: 1000; unit: ""
        arcColor: "#FF3B30"; dangerZone: 0.80
        value: dataModel.rpm; glowIntensity: root._smoothRpmNorm
        centerText: {
            if (!dataModel.engineRunning) return "P"
            if (dataModel.currentGear === 0) return "N"
            return dataModel.currentGear.toString()
        }
        z: 5
    }

    // ── z=0: ПАНЕЛЬ УПРАВЛЕНИЯ ────────────────────────────────────────────────
    ControlsOverlay {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     root.height * 0.008
        width:  root.width  * 0.92
        height: root.height * 0.138
        z: 0
    }
}
