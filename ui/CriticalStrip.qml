// ============================================================================
// CriticalStrip.qml — полоса критических ошибок (красные индикаторы)
//
// ЛОГИКА v6:
//   • startupMode=true  → self-check: все индикаторы светятся (тусклые если не активны)
//   • startupMode=false, systemActive=true, engineRunning=false  → "ignition":
//     горят только АКТИВНЫЕ (handbrake если включён и т.д.)
//   • engineRunning=true → горят только АКТИВНЫЕ ошибки
//   • systemActive=false → ничего не горит (двигатель выключен)
//
//   Мигание: единый централизованный таймер (BlinkController), не индивидуальные анимации.
//   Race condition устранён: opacity управляется ОДНИМ источником (_blinkMul * _fadeOp).
// ============================================================================

import QtQuick 2.15

Item {
    id: root

    property real iconSz:        52
    // self-check режим: все иконки показаны (часть тускло)
    property bool startupMode:   false
    // двигатель запущен
    property bool engineRunning: false
    // система активна (зажигание включено или двигатель работает)
    property bool systemActive:  false

    property int forcedColumns:      0
    property real defaultIconScale:  1.0

    readonly property int iconsPerRow:
        forcedColumns > 0
            ? forcedColumns
            : Math.max(1, Math.floor(root.width / (root.iconSz * 1.22)))

    // ── Список критических индикаторов ────────────────────────────────────────
    // ВАЖНО: индикатор ручника (brakeSystem) горит пока он активен — независимо от фазы.
    // Остальные критические гасятся после запуска двигателя при отсутствии ошибок.
    // iconScale: индивидуальный масштаб иконки внутри ячейки (1.0 = стандарт)
    readonly property var allItems: [
        { icon: "qrc:/assets/icons/red_handbrake.png",                          active: false,                           level: "critical", iconScale: 0.7, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_low_battery.png",                        active: dataModel.batteryFault,          level: "critical", iconScale: 0.7, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_brake_fluid.png",                        active: dataModel.brakeFluid,            level: "critical", iconScale: 0.7, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_engine_oil_level.png",                   active: dataModel.oilPressure,           level: "critical", iconScale: 0.85, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_engine_overheating.png",                 active: dataModel.overheating,           level: "critical", iconScale: 0.6, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_brake.png",                              active: dataModel.brakeSystem,           level: "critical", iconScale: 0.85, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_seatbelt.png",                           active: dataModel.seatbelt,              level: "critical", iconScale: 0.55, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_problems_airbags.png",                   active: dataModel.airbagFault,           level: "critical", iconScale: 0.5, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_automatic_transmission.png",             active: dataModel.transmissionFault,     level: "critical", iconScale: 0.7, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_automatic_transmission_overheating.png", active: dataModel.transmissionOverheat,  level: "critical", iconScale: 0.7, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_power_steering.png",                     active: dataModel.steeringFault,         level: "critical", iconScale: 0.7, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_problems_alarm.png",                     active: dataModel.generalWarning,        level: "critical", iconScale: 0.7, alwaysShow: false },
        { icon: "qrc:/assets/icons/red_triangle.png",                           active: dataModel.generalWarning,        level: "critical", iconScale: 0.7, alwaysShow: false }
    ]

    // Вычисляем что показывать для каждого слота:
    //   startupMode  → показываем всё (self-check)
    //   иначе        → только если active === true
    //                  (alwaysShow=true игнорирует engineRunning для ручника)
    readonly property var displayItems: {
        var res = []
        for (var i = 0; i < allItems.length; i++) {
            var item = allItems[i]
            // Не показывать ничего когда система выключена
            if (!root.systemActive) continue
            var show = root.startupMode ? true : item.active
            res.push({
                icon:      item.icon,
                level:     item.level,
                active:    item.active,
                iconScale: item.iconScale !== undefined ? item.iconScale : root.defaultIconScale,
                show:      show
            })
        }
        return res
    }

    readonly property var visibleItems: {
        var res = []
        for (var i = 0; i < displayItems.length; i++)
            if (displayItems[i].show) res.push(displayItems[i])
        return res
    }

    readonly property real cellW: root.iconSz * 1.22
    readonly property real cellH: root.iconSz * 1.22

    // ── Централизованный таймер мигания ────────────────────────────────────
    // Единый источник истины: нет рассинхрона между индикаторами
    property bool _blinkOn: true

    Timer {
        id: blinkTimer
        interval: 1000
        repeat:   true
        running:  root.systemActive
        onTriggered: root._blinkOn = !root._blinkOn
        onRunningChanged: if (!running) root._blinkOn = true
    }

    Repeater {
        model: visibleItems.length
        delegate: Item {
            id: chip
            required property int index
            readonly property var d: visibleItems[index]

            readonly property int col:      index % iconsPerRow
            readonly property int row_:     Math.floor(index / iconsPerRow)
            readonly property int rowCount_: Math.min(iconsPerRow, visibleItems.length - row_ * iconsPerRow)
            readonly property real rowStartX: (root.width - rowCount_ * cellW) / 2.0
            readonly property real targetX:   rowStartX + col * cellW + (cellW - iconSz) / 2
            readonly property real topOffset: 120
            readonly property real targetY:   row_ * cellH + (cellH - iconSz) / 2 + topOffset

            width:  iconSz
            height: iconSz
            x:      targetX

            readonly property color ac: "#FF3B30"

            // Два независимых множителя opacity — исключает race condition:
            //   _fadeOp  — управляется появлением/исчезновением (0.0 ↔ 1.0)
            //   _blinkMul — управляется миганием (1.0 ↔ 0.12)
            property real _fadeOp:   0.0
            property real _blinkMul: 1.0
            property real scaleVal:  0.65
            property real slideOffset: -iconSz * 2.8

            // Итоговая прозрачность — произведение двух множителей
            opacity: _fadeOp * _blinkMul

            y: targetY + slideOffset

            transform: Scale {
                xScale: chip.scaleVal; yScale: chip.scaleVal
                origin.x: chip.width / 2; origin.y: chip.height / 2
            }

            Component.onCompleted: {
                var gridDelay = row_ * 120 + col * 40
                appearAnim.delay = gridDelay
                appearAnim.start()
            }

            // ── Появление ──────────────────────────────────────────────────
            SequentialAnimation {
                id: appearAnim
                property int delay: 0
                PauseAnimation { duration: appearAnim.delay }
                ParallelAnimation {
                    NumberAnimation { target: chip; property: "slideOffset"; from: -iconSz*2.8; to: 0;   duration: 700; easing.type: Easing.OutExpo }
                    NumberAnimation { target: chip; property: "_fadeOp";     from: 0.0;         to: 1.0; duration: 550; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: chip; property: "scaleVal";    from: 0.65;        to: 1.0; duration: 700; easing.type: Easing.OutExpo }
                }
            }

            // ── Исчезновение ───────────────────────────────────────────────
            SequentialAnimation {
                id: fadeOutAnim
                NumberAnimation { target: chip; property: "_fadeOp"; to: 0.0; duration: 200; easing.type: Easing.InQuad }
                ScriptAction { script: chip.visible = false }
            }

            NumberAnimation {
                id: fadeInAnim
                target: chip; property: "_fadeOp"; to: 1.0; duration: 150; easing.type: Easing.OutQuad
            }

            // ── Реакция на изменение активности ────────────────────────────
            // Вызывается при изменении startupMode ИЛИ active
            function updateVisibility() {
                if (root.startupMode) {
                    // self-check: показываем всё
                    chip.visible = true
                    if (chip._fadeOp < 0.5) fadeInAnim.start()
                } else if (!d.active) {
                    // Нет ошибки — гасим
                    fadeOutAnim.start()
                } else {
                    // Есть ошибка — зажигаем
                    chip.visible = true
                    if (chip._fadeOp < 0.5) fadeInAnim.start()
                }
            }

            Connections {
                target: root
                function onStartupModeChanged() { chip.updateVisibility() }
                function onEngineRunningChanged() { chip.updateVisibility() }
            }

            // ── Мигание критических (через централизованный таймер) ────────
            // Только когда ошибка активна, двигатель работает, self-check завершён
            Binding {
                target: chip
                property: "_blinkMul"
                value: {
                    var shouldBlink = d.active
                                   && root.engineRunning
                                   && !root.startupMode
                                   && chip.slideOffset === 0
                    if (shouldBlink) return root._blinkOn ? 1.0 : 0.12
                    return 1.0
                }
            }

            // ── Визуал ─────────────────────────────────────────────────────
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Qt.rgba(chip.ac.r * 0.08, chip.ac.g * 0.08, chip.ac.b * 0.08, 1.0)
                border.color: Qt.rgba(chip.ac.r, chip.ac.g, chip.ac.b, 0.45)
                border.width: 1.2
                opacity: (root.startupMode && !chip.d.active) ? 0.4 : 1.0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }

            Image {
                anchors.centerIn: parent
                width:  iconSz * d.iconScale
                height: width
                source: d.icon
                fillMode: Image.PreserveAspectFit
                smooth: true; antialiasing: true
                opacity: (root.startupMode && !chip.d.active) ? 0.35 : 1.0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }
    }
}
