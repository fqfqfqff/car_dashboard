import QtQuick 2.15

Item {
    id: root
    anchors.fill: parent

    property string startupPhase:    "idle"
    property real   centerUIOpacity: 0.0
    property real   centerWidthRatio:  0.28
    property real   centerHeightRatio: 0.82

    readonly property real gaugeSize: Math.min(root.height * 0.76, root.width * 0.38)
    readonly property real rpmNorm:   Math.min(1.0, dataModel.rpm / 8000.0)

    // ── ЗАПУСК / ОСТАНОВКА ──────────────────────────────────────────────────
    Connections {
        target: dataModel
        function onEngineRunningChanged() {
            if (dataModel.engineRunning) {
                root.startupPhase    = "sweep"
                root.centerUIOpacity = 0.0
                rpmGauge.startSweep()
                speedGauge.startSweep()
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
        id: selfCheckTimer; interval: 3500; repeat: false
        onTriggered: { if (root.startupPhase === "sweep") root.startupPhase = "normal" }
    }

    NumberAnimation {
        id: centerFadeIn; target: root; property: "centerUIOpacity"
        from: 0.0; to: 1.0; duration: 700; easing.type: Easing.InOutQuad; running: false
    }

    // ── ОБЩИЙ ФОН ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#05050A"
    }

    // Виньетка по краям
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: "#50000008" }
            GradientStop { position: 0.18; color: "transparent" }
            GradientStop { position: 0.82; color: "transparent" }
            GradientStop { position: 1.00; color: "#50000008" }
        }
    }

    // Горизонтальная подсветка снизу (ambient red glow)
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height: root.height * 0.12
        opacity: root.startupPhase !== "idle" ? (0.18 + rpmNorm * 0.22) : 0.0
        Behavior on opacity { NumberAnimation { duration: 800 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#FF3B30" }
        }
    }

    // ── TOP STRIP: поворотники, свет, ABS, круиз ─────────────────────────────
    Item {
        id: topStrip
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: root.height * 0.068

        opacity: root.startupPhase !== "idle" ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 500 } }

        // Фон полосы
        Rectangle {
            anchors.fill: parent
            color: "#08080F"
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0;  color: "transparent" }
                    GradientStop { position: 0.15; color: "#1E1E2E" }
                    GradientStop { position: 0.85; color: "#1E1E2E" }
                    GradientStop { position: 1.0;  color: "transparent" }
                }
            }
        }

        // Поворотник левый
        Image {
            anchors.left:           parent.left
            anchors.leftMargin:     parent.width * 0.04
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height * 0.62
            width:  height
            source: "qrc:/assets/icons/turn_left.png"
            fillMode: Image.PreserveAspectFit
            visible: dataModel.turnLeft
            opacity: (dataModel.turnLeft && !dataModel.turnRight) || (dataModel.turnLeft && dataModel.turnRight)
                     ? BlinkController.blinkState ? 1.0 : 0.0
                     : 0.0
            Behavior on opacity { NumberAnimation { duration: 50 } }
        }

        // Поворотник правый
        Image {
            anchors.right:          parent.right
            anchors.rightMargin:    parent.width * 0.04
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height * 0.62
            width:  height
            source: "qrc:/assets/icons/turn_right.png"
            fillMode: Image.PreserveAspectFit
            visible: dataModel.turnRight
            opacity: (dataModel.turnRight && !dataModel.turnLeft) || (dataModel.turnLeft && dataModel.turnRight)
                     ? BlinkController.blinkState ? 1.0 : 0.0
                     : 0.0
            Behavior on opacity { NumberAnimation { duration: 50 } }
        }

        // Центральные индикаторы (свет, ABS, круиз)
        Row {
            anchors.centerIn: parent
            spacing: parent.width * 0.018

            // Ближний свет
            TopIcon {
                source: "qrc:/assets/icons/low_beam.png"
                active: dataModel.lowBeam
                activeColor: "#0A84FF"
            }
            // Дальний свет
            TopIcon {
                source: "qrc:/assets/icons/high_beam.png"
                active: dataModel.highBeam
                activeColor: "#4488FF"
            }
            // Туман
            TopIcon {
                source: "qrc:/assets/icons/fog.png"
                active: dataModel.fogLights
                activeColor: "#30D158"
            }

            // Разделитель
            Rectangle {
                width: 1; height: topStrip.height * 0.40
                color: "#1C1C28"
                anchors.verticalCenter: parent.verticalCenter
            }

            // ABS
            TopIcon {
                source: "qrc:/assets/icons/abs.png"
                active: dataModel.absActive
                activeColor: "#FFCC00"
            }
            // ESP
            TopIcon {
                source: "qrc:/assets/icons/esp.png"
                active: dataModel.espActive
                activeColor: "#FFCC00"
            }
            // TPMS
            TopIcon {
                source: "qrc:/assets/icons/tpms.png"
                active: dataModel.tpmsActive
                activeColor: "#FFCC00"
            }
            // Check engine
            TopIcon {
                source: "qrc:/assets/icons/check_engine.png"
                active: dataModel.checkEngine
                activeColor: "#FFCC00"
            }

            // Разделитель
            Rectangle {
                width: 1; height: topStrip.height * 0.40
                color: "#1C1C28"
                anchors.verticalCenter: parent.verticalCenter
            }

            // Круиз-контроль
            TopIcon {
                source: ""
                active: dataModel.cruiseActive
                activeColor: "#30D158"
                label: "CC"
            }
            // OBD
            TopIcon {
                source: ""
                active: dataModel.canConnected
                activeColor: "#30D158"
                label: "OBD"
            }
        }
    }

    // Якорь вертикального центра для циферблатов — объявляем ДО их использования
    Item {
        id: gaugesCenter
        anchors.top:    topStrip.bottom
        anchors.bottom: criticalStrip.top
        anchors.left:   parent.left
        anchors.right:  parent.right
    }

    // ── ТАХОМЕТР (левый) ──────────────────────────────────────────────────────
    Gauge {
        id: rpmGauge
        anchors.left:           parent.left
        anchors.leftMargin:     root.width * 0.004
        anchors.verticalCenter: gaugesCenter.verticalCenter
        width:  root.gaugeSize
        height: root.gaugeSize

        minValue: 0; maxValue: 8000; step: 1000; unit: ""
        arcColor: "#FF3B30"; dangerZone: 0.80
        value: dataModel.rpm
        glowIntensity: root.rpmNorm

        centerText: {
            if (!dataModel.engineRunning) return "P"
            if (dataModel.canConnected && dataModel.currentGear === 0) return ""
            if (dataModel.currentGear === 0) return "N"
            return dataModel.currentGear.toString()
        }

        // Температура ДВС внутри тахометра
        showInnerArc:  true
        innerArcType:  "temp"
        innerArcValue: dataModel.engineTemp
        innerArcMin:   40.0
        innerArcMax:   130.0

        // Индикаторы: ремень (красный) + check engine (жёлтый)
        indicator1Active: dataModel.seatbelt
        indicator1Icon:   "seatbelt"
        indicator2Active: dataModel.checkEngine
        indicator2Icon:   "check"
    }

    // ── СПИДОМЕТР (правый) ───────────────────────────────────────────────────
    Gauge {
        id: speedGauge
        anchors.right:          parent.right
        anchors.rightMargin:    root.width * 0.004
        anchors.verticalCenter: gaugesCenter.verticalCenter
        width:  root.gaugeSize
        height: root.gaugeSize

        minValue: 0; maxValue: 300; step: 20; unit: "km/h"
        arcColor: "#FF3B30"; dangerZone: 0.85
        value: dataModel.speed; centerText: ""
        glowIntensity: root.rpmNorm * 2

        // Топливо внутри спидометра
        showInnerArc:  true
        innerArcType:  "fuel"
        innerArcValue: dataModel.fuelLevel
        innerArcMin:   0.0
        innerArcMax:   100.0

        // Индикаторы: ESP (жёлтый) + TPMS (жёлтый)
        indicator1Active: dataModel.espActive
        indicator1Icon:   "esp"
        indicator2Active: dataModel.tpmsActive
        indicator2Icon:   "esp"
    }

    // ── ЦЕНТРАЛЬНАЯ ЗОНА ──────────────────────────────────────────────────────
    Item {
        id: contentCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:    topStrip.bottom
        anchors.bottom: criticalStrip.top
        anchors.topMargin:    root.height * 0.01
        anchors.bottomMargin: root.height * 0.01
        width: parent.width * root.centerWidthRatio

        opacity: root.startupPhase === "idle" ? 0.0 : root.centerUIOpacity
        Behavior on opacity { NumberAnimation { duration: 400 } }

        IndicatorPanel {
            id: indicatorPanel
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: parent.height * 0.35
        }

        Display {
            id: centerDisplay
            anchors.top:    indicatorPanel.bottom
            anchors.topMargin: root.height * 0.008
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            criticalLabels: indicatorPanel.activeCriticalLabels
            hasCritical:    indicatorPanel.anyCritical
        }
    }

    // ── CRITICAL STRIP: красные индикаторы (горизонтальная линия) ─────────────
    Item {
        id: criticalStrip
        anchors.bottom:       controlsOverlay.top
        anchors.bottomMargin: root.height * 0.008
        anchors.left:         parent.left
        anchors.right:        parent.right
        height: root.height * 0.072

        opacity: root.startupPhase !== "idle" ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 500 } }

        // Фон
        Rectangle {
            anchors.fill: parent
            color: "#06060C"
            Rectangle {
                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0;  color: "transparent" }
                    GradientStop { position: 0.15; color: "#1A1A2A" }
                    GradientStop { position: 0.85; color: "#1A1A2A" }
                    GradientStop { position: 1.0;  color: "transparent" }
                }
            }
        }

        // Горизонтальная линия критических иконок
        Row {
            anchors.centerIn: parent
            spacing: root.width * 0.016

            CriticalIcon { source: "qrc:/assets/icons/red_engine_oil_level.png";              active: dataModel.oilPressure;         blink: true  }
            CriticalIcon { source: "qrc:/assets/icons/red_engine_overheating.png";            active: dataModel.overheating;         blink: true  }
            CriticalIcon { source: "qrc:/assets/icons/red_brake.png";                         active: dataModel.brakeSystem;         blink: false }
            CriticalIcon { source: "qrc:/assets/icons/red_low_battery.png";                   active: dataModel.batteryFault;        blink: true  }
            CriticalIcon { source: "qrc:/assets/icons/red_problems_airbags.png";              active: dataModel.airbagFault;         blink: true  }
            CriticalIcon { source: "qrc:/assets/icons/red_seatbelt.png";                      active: dataModel.seatbelt;            blink: false }
            CriticalIcon { source: "qrc:/assets/icons/red_brake_fluid.png";                   active: dataModel.brakeFluid;          blink: true  }
            CriticalIcon { source: "qrc:/assets/icons/red_handbrake.png";                     active: dataModel.brakeSystem;         blink: false }
            CriticalIcon { source: "qrc:/assets/icons/red_automatic_transmission.png";        active: dataModel.transmissionFault;   blink: true  }
            CriticalIcon { source: "qrc:/assets/icons/red_automatic_transmission_overheating.png"; active: dataModel.transmissionOverheat; blink: true }
            CriticalIcon { source: "qrc:/assets/icons/red_power_steering.png";                active: dataModel.steeringFault;       blink: true  }
            CriticalIcon { source: "qrc:/assets/icons/red_problems_alarm.png";                active: dataModel.generalWarning;      blink: true  }
        }
    }

    // ── WARNING STRIP: жёлтые индикаторы (между criticalStrip и топом) ───────
    // Вынесены в TOP strip — здесь убраны

    // ── ПАНЕЛЬ УПРАВЛЕНИЯ (тестовая) ─────────────────────────────────────────
    ControlsOverlay {
        id: controlsOverlay
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     root.height * 0.005
        width:  root.width  * 0.92
        height: root.height * 0.132
    }

    // ── PanelOutline ──────────────────────────────────────────────────────────
    PanelOutline {}

    // ════════════════════════════════════════════════════════════════════════
    // Inline-компоненты
    // ════════════════════════════════════════════════════════════════════════

    // TopIcon — маленькая иконка в TOP strip
    component TopIcon: Item {
        property string source:      ""
        property bool   active:      false
        property color  activeColor: "#FFCC00"
        property string label:       ""

        width:  topStrip.height * 0.72
        height: topStrip.height * 0.72
        anchors.verticalCenter: parent !== null ? parent.verticalCenter : undefined

        opacity: active ? 1.0 : 0.18
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Image {
            anchors.fill: parent
            source: parent.source
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: parent.source !== ""
        }

        Text {
            anchors.centerIn: parent
            text: parent.label
            font.family:    "Microgramma"
            font.pixelSize: parent.height * 0.38
            color:          parent.active ? parent.activeColor : "#404050"
            visible: parent.label !== ""
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Свечение при активном состоянии
        Rectangle {
            anchors.centerIn: parent
            width:   parent.width  * 1.8
            height:  parent.height * 1.8
            radius:  width / 2
            color:   "transparent"
            border.color: parent.activeColor
            border.width: 1
            opacity: parent.active ? 0.35 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // CriticalIcon — иконка в нижней критической полосе
    component CriticalIcon: Item {
        property string source: ""
        property bool   active: false
        property bool   blink:  false

        readonly property real iconH: criticalStrip.height * 0.62

        width:  iconH * 1.1
        height: iconH

        property bool _blinkState: true
        Timer {
            interval: 600; running: parent.active && parent.blink; repeat: true
            onTriggered: parent._blinkState = !parent._blinkState
            onRunningChanged: if (!running) parent._blinkState = true
        }

        // Фоновый квадрат при активном состоянии
        Rectangle {
            anchors.centerIn: parent
            width:   parent.iconH * 1.05
            height:  parent.iconH * 1.05
            radius:  4
            color:   Qt.rgba(1.0, 0.23, 0.19, 0.12)
            border.color: Qt.rgba(1.0, 0.23, 0.19, 0.55)
            border.width: 1
            visible: parent.active
            opacity: parent._blinkState ? 1.0 : 0.2
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        Image {
            anchors.centerIn: parent
            width:   parent.iconH * 0.75
            height:  width
            source:  parent.source
            fillMode: Image.PreserveAspectFit
            smooth:  true

            opacity: {
                if (!parent.active) return 0.12
                if (parent.blink)   return parent._blinkState ? 1.0 : 0.15
                return 1.0
            }
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }
}
