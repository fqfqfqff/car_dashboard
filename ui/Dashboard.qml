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

    // Центры гаджей (для построения дуг центральной панели)
    readonly property real speedCX: gaugeMarH + gaugeR
    readonly property real rpmCX:   root.width - gaugeMarH - gaugeR

    // Высота панели: отступ displayPadV с каждой стороны.
    // Увеличен → больше места для стрипов индикаторов (крупнее иконки).
    readonly property real displayPadV: gaugeSize * 0.128
    readonly property real displayY: gaugeTop    + displayPadV
    readonly property real displayH: gaugeBottom - gaugeTop - displayPadV * 2

    // Радиус видимого диска гаджа (bgR в GaugeItem.cpp ≈ 0.95·gaugeR).
    // Дуги панели идут точно по нему, чтобы касаться приборов без зазора.
    readonly property real gaugeArcR: gaugeR * 0.95

    // Горизонтальная протяжённость вогнутых дуг на уровне верхней/нижней границы
    readonly property real _dispEdgeD:   gaugeCY - displayY   // вертикальное расстояние от центра гаджа до края панели
    readonly property real _arcAtEdge:   Math.sqrt(Math.max(0, gaugeArcR * gaugeArcR - _dispEdgeD * _dispEdgeD))

    // Item панели охватывает всю фигуру (самая широкая часть — у верхнего/нижнего края)
    readonly property real displayX: speedCX + _arcAtEdge
    readonly property real displayW: (rpmCX - _arcAtEdge) - (speedCX + _arcAtEdge)

    // Стрипы между верхом гаджей и Display
    // Ошибки (красные) — выше, варнинги (жёлтые) — ниже.
    readonly property real stripZoneTop:    gaugeTop + gaugeSize * 0.015
    readonly property real stripZoneBottom: displayY - root.height * 0.014
    readonly property real stripW:          rpmInnerX - speedInnerX - gaugeSize * 0.06

    readonly property real warnZoneTop:    displayY + displayH + root.height * 0.018
    readonly property real warnZoneBottom: gaugeBottom - gaugeSize * 0.015

    // RPM-свечение — сглаженное
    readonly property real rpmNorm: Math.min(1.0, dataModel.rpm / 8000.0)
    property real _smoothRpmNorm: 0.0
    Behavior on _smoothRpmNorm {
        NumberAnimation { duration: 1000; easing.type: Easing.OutCubic }
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
        iconSz: Math.min(78, height * 0.74)
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
        iconSz: Math.min(78, height * 0.74)
        startupMode:   root.startupPhase === "sweep"
        engineRunning: dataModel.engineRunning
        systemActive:  root.startupPhase !== "idle"
        z: 1; clip: true
    }

    // ── z=2: КОНТУР КЛАСТЕРА ─────────────────────────────────────────────────
    PanelOutline { anchors.fill: parent; z: 2 }

    // ── z=3: ЦЕНТРАЛЬНАЯ ПАНЕЛЬ ─────────────────────────────────────────────
    // Боковые дуги — вогнутые, повторяют окружности спидометра / тахометра.
    // Верх/низ — прямые горизонтальные линии до точек касания с дугами.
    Display {
        id: centerDisplay
        x:      root.displayX
        y:      root.displayY
        width:  root.displayW
        height: root.displayH
        gaugeR:      root.gaugeR
        arcR:        root.gaugeArcR
        // Координаты центров гаджей в локальной системе Display
        speedCXLocal: root.speedCX - root.displayX
        rpmCXLocal:   root.rpmCX   - root.displayX
        gaugeCYLocal: root.gaugeCY - root.displayY
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
        minValue: 0; maxValue: 300; step: 20; unit: "км/ч"
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

    // ── z=4: КРАСНЫЕ АКЦЕНТНЫЕ ЛИНИИ (по верхнему/нижнему краю панели) ───────
    Rectangle {
        x: root.displayX
        y: root.displayY
        width: root.displayW
        height: 1.5
        z: 4
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.06; color: "#CC2820" }
            GradientStop { position: 0.50; color: "#CC2820" }
            GradientStop { position: 0.94; color: "#CC2820" }
            GradientStop { position: 1.0;  color: "transparent" }
        }
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity * 0.65
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    }
    Rectangle {
        x: root.displayX
        y: root.displayY
        width: root.displayW
        height: root.height * 0.010
        z: 3
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1.0, 0.16, 0.12, 0.14) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    }

    Rectangle {
        x: root.displayX
        y: root.displayY + root.displayH - 1.5
        width: root.displayW
        height: 1.5
        z: 4
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.06; color: "#CC2820" }
            GradientStop { position: 0.50; color: "#CC2820" }
            GradientStop { position: 0.94; color: "#CC2820" }
            GradientStop { position: 1.0;  color: "transparent" }
        }
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity * 0.55
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    }
    Rectangle {
        x: root.displayX
        y: root.displayY + root.displayH - root.height * 0.010
        width: root.displayW
        height: root.height * 0.010
        z: 3
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(1.0, 0.16, 0.12, 0.11) }
        }
        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    }

    // ── z=6: ПОВОРОТНИКИ — у границ спидометра / тахометра ───────────────────
    // Центрированы на внутреннем крае каждого гаджа, в верхней зоне стрипов.
    Image {
        x: root.speedInnerX - width / 2
        y: root.stripZoneTop + root.gaugeSize * 0.004
        width: root.gaugeSize * 0.105
        height: root.gaugeSize * 0.072
        source: "qrc:/assets/icons/turn_left.png"
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: dataModel.turnLeft
        opacity: BlinkController.blinkState ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 80 } }
        z: 6
    }

    Image {
        x: root.rpmInnerX - width / 2
        y: root.stripZoneTop + root.gaugeSize * 0.004
        width: root.gaugeSize * 0.105
        height: root.gaugeSize * 0.072
        source: "qrc:/assets/icons/turn_right.png"
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: dataModel.turnRight
        opacity: BlinkController.blinkState ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 80 } }
        z: 6
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
