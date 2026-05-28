// ============================================================================
// WarningStrip.qml — полоса предупреждений (жёлтые индикаторы)
//
// ЛОГИКА v6:
//   • startupMode=true  → self-check: все индикаторы светятся (тусклые если не активны)
//   • После self-check   → горят только АКТИВНЫЕ предупреждения
//   • systemActive=false → ничего не горит (двигатель выключен, зажигание выключено)
//   • engineRunning=false, systemActive=true → предупреждения НЕ горят
//     (предупреждения имеют смысл только при работающем двигателе)
//   • Мигание для жёлтых НЕ используется — они горят постоянно (по стандарту)
// ============================================================================

import QtQuick 2.15

Item {
    id: root

    property real iconSz:        52
    property bool startupMode:   false
    property bool engineRunning: false
    property bool systemActive:  false

    property int forcedColumns:      0
    property real defaultIconScale:  1.0

    readonly property int iconsPerRow:
        forcedColumns > 0
            ? forcedColumns
            : Math.max(1, Math.floor(root.width / (root.iconSz * 1.22)))

    // Жёлтые (warning) индикаторы.
    // Показываются ТОЛЬКО при работающем двигателе (или self-check).
    // iconScale: индивидуальный масштаб иконки внутри ячейки (1.0 = стандарт)
    readonly property var allItems: [
        { icon: "qrc:/assets/icons/check_engine.png", active: dataModel.checkEngine,  level: "warning", iconScale: 0.85 },
        { icon: "qrc:/assets/icons/abs.png",          active: dataModel.absActive,    level: "warning", iconScale: 0.85 },
        { icon: "qrc:/assets/icons/esp.png",          active: dataModel.espActive,    level: "warning", iconScale: 0.85 },
        { icon: "qrc:/assets/icons/tpms.png",         active: dataModel.tpmsActive,   level: "warning", iconScale: 0.85 },
        { icon: "qrc:/assets/icons/fuel_low.png",     active: dataModel.fuelLow,      level: "warning", iconScale: 0.85 },
        { icon: "qrc:/assets/icons/temp.png",         active: dataModel.overheating,  level: "warning", iconScale: 0.85 },
        { icon: "qrc:/assets/icons/oil.png",          active: dataModel.oilPressure,  level: "warning", iconScale: 0.85 },
        { icon: "qrc:/assets/icons/battery.png",      active: dataModel.batteryFault, level: "warning", iconScale: 0.85 },
    ]

    readonly property var displayItems: {
        var res = []
        for (var i = 0; i < allItems.length; i++) {
            var item = allItems[i]
            // Ничего не показываем при выключенной системе
            if (!root.systemActive) continue
            // При self-check показываем всё
            // После self-check — только при работающем двигателе и только активные
            var show = root.startupMode
                       ? true
                       : (root.engineRunning && item.active)
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
            readonly property real targetY:   root.height - (row_ + 1) * cellH + (cellH - iconSz) / 2

            width:  iconSz
            height: iconSz
            x:      targetX

            readonly property color ac: "#FFCC00"

            // Только один источник для opacity — нет race condition
            property real _fadeOp:    0.0
            property real scaleVal:   0.65
            property real slideOffset: -iconSz * 2.8

            opacity: _fadeOp
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

            SequentialAnimation {
                id: fadeOutAnim
                NumberAnimation { target: chip; property: "_fadeOp"; to: 0.0; duration: 200; easing.type: Easing.InQuad }
                ScriptAction { script: chip.visible = false }
            }

            NumberAnimation {
                id: fadeInAnim
                target: chip; property: "_fadeOp"; to: 1.0; duration: 150; easing.type: Easing.OutQuad
            }

            function updateVisibility() {
                if (root.startupMode) {
                    chip.visible = true
                    if (chip._fadeOp < 0.5) fadeInAnim.start()
                } else if (!root.engineRunning || !d.active) {
                    fadeOutAnim.start()
                } else {
                    chip.visible = true
                    if (chip._fadeOp < 0.5) fadeInAnim.start()
                }
            }

            Connections {
                target: root
                function onStartupModeChanged()   { chip.updateVisibility() }
                function onEngineRunningChanged()  { chip.updateVisibility() }
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
