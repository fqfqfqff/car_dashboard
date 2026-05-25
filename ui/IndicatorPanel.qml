// =============================================================================
// IndicatorPanel.qml — Панель индикаторов. Переработка v4.
//
// КОНЦЕПЦИЯ:
//   • Только активные индикаторы видны — остальных нет на экране вообще
//   • Flow раскладка: при 1-3 активных → одна строка по центру
//                     при 4+ активных  → автоматический перенос в 2 строки
//   • Три зоны по приоритету: CRITICAL / WARNING / INFO
//   • Анимация появления: scale 0.65→1.0 + opacity 0→1 + y offset (OutBack)
//   • Мигание критических через отдельный _blinkVal (не конфликтует с Behavior)
//
// ИСПРАВЛЕНЫ ОШИБКИ vs. v3:
//   • fuel_low.svg → fuel_low.png
//   • steering.svg → red_power_steering.png (используется в WarningStrip)
//   • cruise.svg   → Canvas-иконка
//   • low_beam.svg / high_beam.svg → .png
//   • SequentialAnimation on opacity конфликтовал с Behavior → исправлено
//   • startupMode убран полностью
// =============================================================================

import QtQuick 2.15

Item {
    id: root

    // Список активных критических для Display.qml
    readonly property var activeCriticalLabels: {
        var list = []
        if (typeof dataModel !== "undefined") {
            if (dataModel.oilPressure)          list.push("ДАВЛЕНИЕ МАСЛА")
            if (dataModel.overheating)          list.push("ПЕРЕГРЕВ ДВС")
            if (dataModel.brakeSystem)          list.push("ТОРМОЗНАЯ СИСТЕМА")
            if (dataModel.batteryFault)         list.push("АККУМУЛЯТОР")
            if (dataModel.airbagFault)          list.push("ПОДУШКИ БЕЗОПАСНОСТИ")
            if (dataModel.seatbelt)             list.push("ПРИСТЕГНИТЕ РЕМЕНЬ")
            if (dataModel.brakeFluid)           list.push("ТОРМОЗНАЯ ЖИДКОСТЬ")
            if (dataModel.transmissionFault)    list.push("НЕИСПРАВНОСТЬ АКПП")
            if (dataModel.transmissionOverheat) list.push("ПЕРЕГРЕВ АКПП")
        }
        return list
    }

    readonly property bool anyCritical: activeCriticalLabels.length > 0

    // Размеры плиток
    readonly property real critSz: Math.min(root.width * 0.088, root.height * 0.36)
    readonly property real warnSz: critSz * 0.80
    readonly property real infoSz: critSz * 0.66

    // ── ЗОНА ИНФОРМАЦИОННЫХ (нижняя ~23%) ────────────────────────────────────
    // Item {
    //     id: infoZone
    //     anchors.top:    div2.bottom
    //     anchors.bottom: parent.bottom
    //     anchors.left:   parent.left
    //     anchors.right:  parent.right

    //     Flow {
    //         id: infoFlow
    //         anchors.centerIn: parent
    //         spacing: root.width * 0.008
    //         width: root.width * 0.96
    //         layoutDirection: Qt.LeftToRight

    //         IndicChip {
    //             sz: root.infoSz; level: "info"; lbl: "БЛИЖН."
    //             iconSrc: "qrc:/assets/icons/low_beam.png"
    //             noBackground: true
    //             active: typeof dataModel !== "undefined" ? dataModel.lowBeam : false
    //         }
    //         IndicChip {
    //             sz: root.infoSz; level: "info"; lbl: "ДАЛЬН."
    //             iconSrc: "qrc:/assets/icons/high_beam.png"
    //             noBackground: true
    //             active: typeof dataModel !== "undefined" ? dataModel.highBeam : false
    //         }
    //         IndicChip {
    //             sz: root.infoSz; level: "info"; lbl: "ТУМАН"
    //             iconSrc: "qrc:/assets/icons/fog.svg"
    //             noBackground: true
    //             active: typeof dataModel !== "undefined" ? dataModel.fogLights : false
    //         }
    //         IndicChip {
    //             sz: root.infoSz
    //             level: "info"
    //             lbl: ""
    //             noBackground: true    // если нужно прозрачное поле
    //             useCanvasIcon: false
    //             active: typeof dataModel !== "undefined" ? dataModel.cruiseActive : false
    //         }
    //     }
    // }

    // ════════════════════════════════════════════════════════════════════════
    // КОМПОНЕНТ ПЛИТКИ
    // ════════════════════════════════════════════════════════════════════════
    component IndicChip: Item {
        id: chip

        property real sz:            52
        property string iconSrc:     ""
        property string lbl:         ""
        property string level:       "off"
        property bool active:        false
        property bool noBackground:  false
        property bool useCanvasIcon: false

        width: sz * 1.28
        height: sz * 1.52
        visible: false

        readonly property color levelColor: {
            switch (chip.level) {
                case "critical": return "#FF3B30"
                case "warning":  return "#FFCC00"
                case "info":     return "#0A84FF"
                default:         return "#404050"
            }
        }

        // ── Анимируемые свойства ──────────────────────────────
        property real _op:       0.0
        property real _sc:       0.65
        property real _yOff:     0.0
        property real _glow:     0.0
        property real _targetX:  0
        property real _targetY:  0
        property real _blinkVal: 1.0

        opacity: _op * _blinkVal
        scale: _sc
        x: _targetX
        y: _targetY + _yOff

        onActiveChanged: {
            if (active) {
                visible = true
                // Рассчитываем стартовую позицию — центр родителя
                _yOff = -sz*2.8
                _targetX = parent.width / 2 - width / 2
                _targetY = y // текущая позиция Flow
                appearAnim.restart()
            } else {
                disappearAnim.restart()
            }
        }

        // ── Появление из верхнего центра с разлетом по Flow ──
        SequentialAnimation {
            id: appearAnim
            running: false

            PauseAnimation {
                duration: {
                    if (chip.parent) {
                        var idx = chip.parent.children.indexOf(chip)
                        return idx * 60 // 60ms между плитками
                    }
                    return 0
                }
            }

            ParallelAnimation {
                // Плитка падает сверху и смещается по x к позиции в Flow
                NumberAnimation { target: chip; property: "_yOff"; from: -sz*2.8; to: 0; duration: 700; easing.type: Easing.OutBack }
                NumberAnimation { target: chip; property: "_op";   from: 0.0; to: 1.0; duration: 550; easing.type: Easing.InOutCubic }
                NumberAnimation { target: chip; property: "_sc";   from: 0.65; to: 1.0; duration: 700; easing.type: Easing.OutBack }
                NumberAnimation { target: chip; property: "_targetX"; from: parent.width/2 - width/2; to: x; duration: 700; easing.type: Easing.OutBack }

                SequentialAnimation { // Glow вспышка
                    PauseAnimation { duration: 200 }
                    NumberAnimation { target: chip; property: "_glow"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: chip; property: "_glow"; from: 1.0; to: 0.0; duration: 500; easing.type: Easing.InCubic }
                }
            }
        }

        // ── Исчезновение плитки ────────────────────────────────
        SequentialAnimation {
            id: disappearAnim
            running: false
            ParallelAnimation {
                NumberAnimation { target: chip; property: "_op";  to: 0.0; duration: 180; easing.type: Easing.InQuad }
                NumberAnimation { target: chip; property: "_sc";  to: 0.80; duration: 180; easing.type: Easing.InQuad }
                NumberAnimation { target: chip; property: "_yOff"; to: -sz*2.8; duration: 180; easing.type: Easing.InQuad }
            }
            ScriptAction { script: { chip.visible = false; _sc=0.65; _yOff=-sz*2.8; _op=0; _glow=0 } }
        }

        // ── Мигание критических ───────────────────────────────
        SequentialAnimation {
            id: blinkAnim
            running: chip.active && chip.level === "critical"
            loops: Animation.Infinite
            NumberAnimation { target: chip; property: "_blinkVal"; to: 0.12; duration: 450; easing.type: Easing.InOutSine }
            NumberAnimation { target: chip; property: "_blinkVal"; to: 1.0;  duration: 450; easing.type: Easing.InOutSine }
            onStopped: chip._blinkVal = 1.0
        }

        // ── Визуальные элементы ───────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: 10
            visible: !chip.noBackground
            color: Qt.rgba(levelColor.r*0.1, levelColor.g*0.1, levelColor.b*0.1, 1.0)
            border.width: 1.2
            border.color: Qt.rgba(levelColor.r, levelColor.g, levelColor.b, 0.55)
        }

        Rectangle { // Glow
            anchors.centerIn: parent
            width:  parent.width  * 1.45
            height: parent.height * 1.30
            radius: 18
            color: "transparent"
            visible: chip.level === "critical"
            border.color: levelColor
            border.width: 1.2
            opacity: _glow
        }

        Loader {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: sz*0.22
            width:  sz * 0.54
            height: sz * 0.54
            sourceComponent: chip.useCanvasIcon ? canvasComp : imageComp
        }

        Component {
            id: imageComp
            Image {
                anchors.fill: parent
                source: chip.iconSrc
                fillMode: Image.PreserveAspectFit
                smooth: true; antialiasing: true
                visible: chip.iconSrc !== ""
            }
        }

        Component {
            id: canvasComp
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0,0,width,height)
                    ctx.strokeStyle="#0A84FF"
                    ctx.lineWidth=width*0.10
                    ctx.lineCap="round"
                    var cx=width/2,cy=height/2,r=width*0.34
                    ctx.beginPath()
                    ctx.arc(cx,cy,r,Math.PI*0.80,Math.PI*2.20,false)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.moveTo(cx-r*0.25,cy-r*0.55)
                    ctx.lineTo(cx+r*0.50,cy)
                    ctx.lineTo(cx-r*0.25,cy+r*0.55)
                    ctx.stroke()
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: sz*0.13
            text: lbl
            font.family: "Microgramma"
            font.pixelSize: sz*0.182
            font.letterSpacing: 0.8
            color: levelColor
        }
    }
}
