// =============================================================================
// HeadlightStrip.qml — индикаторы фар. Финальная версия.
//
// КЛЮЧЕВЫЕ ИЗМЕНЕНИЯ vs. оригинала:
//
//   Low beam / High beam — ОДИН СЛОТ:
//     Проблема оригинала: при переключении лампы "прыгали" по layout.
//     Решение: crossfade в одной позиции (фиксированный якорь).
//
//   Fog lights — отдельная позиция справа, фиксированный якорь.
//
//   Cruise icon УДАЛЁН (по ТЗ — "Remove cruise icon completely").
//   Круиз отображается только текстом в Display.qml.
//
// ПОЗИЦИОНИРОВАНИЕ (без layout shift):
//   ┌──────────────┬──────────────┐
//   │ [beam slot]  │ [fog slot]   │
//   │ low XOR high │              │
//   └──────────────┴──────────────┘
//
// Ширина полосы = parent.width, позиции фиксированы по центру/смещению.
// =============================================================================

import QtQuick 2.15

Item {
    id: root
    property real iconSz: 52

    // ── Слот 1: ближний/дальний (crossfade, один якорь) ───────────────────────

    Item {
        id: beamSlot
        // Фиксированная позиция — НИКОГДА не двигается
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -root.iconSz * 0.70
        anchors.verticalCenter: parent.verticalCenter
        width:  root.iconSz
        height: root.iconSz

        // Видим только если хотя бы один тип фар активен
        visible: dataModel.lowBeam || dataModel.highBeam

        // ── Ближний (низ иерархии) ─────────────────────────────────────────
        Item {
            anchors.fill: parent

            // Crossfade: lowBeam ON → highBeam fade-out (и наоборот)
            opacity: (dataModel.lowBeam && !dataModel.highBeam) ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            Rectangle {
                anchors.fill: parent; radius: width / 2
                color:        Qt.rgba(0.04, 0.52, 1.0, 0.09)
                border.color: Qt.rgba(0.04, 0.52, 1.0, 0.38)
                border.width: 1.1
            }
            Image {
                anchors.centerIn: parent
                width: root.iconSz * 0.58; height: width
                source: "qrc:/assets/icons/low_beam.png"
                fillMode: Image.PreserveAspectFit; smooth: true
            }
        }

        // ── Дальний (высокий приоритет, поверх ближнего) ──────────────────
        Item {
            anchors.fill: parent

            opacity: dataModel.highBeam ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            Rectangle {
                anchors.fill: parent; radius: width / 2
                color:        Qt.rgba(0.20, 0.60, 1.0, 0.09)
                border.color: Qt.rgba(0.20, 0.60, 1.0, 0.42)
                border.width: 1.1
            }
            Image {
                anchors.centerIn: parent
                width: root.iconSz * 0.58; height: width
                source: "qrc:/assets/icons/high_beam.png"
                fillMode: Image.PreserveAspectFit; smooth: true
            }
        }
    }

    // ── Слот 2: противотуманки (фиксированный, рядом с beam) ─────────────────
    Item {
        id: fogSlot
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.iconSz * 0.70
        anchors.verticalCenter: parent.verticalCenter
        width:  root.iconSz
        height: root.iconSz

        opacity: dataModel.fogLights ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        Rectangle {
            anchors.fill: parent; radius: width / 2
            color:        Qt.rgba(0.19, 0.82, 0.35, 0.09)
            border.color: Qt.rgba(0.19, 0.82, 0.35, 0.38)
            border.width: 1.1
        }
        Image {
            anchors.centerIn: parent
            width: root.iconSz * 0.58; height: width
            source:   "qrc:/assets/icons/fog.png"
            fillMode: Image.PreserveAspectFit; smooth: true
        }
    }
}
