    // =============================================================================
// TurnSignals.qml — поворотники и аварийка (standalone компонент)
//
// Используется в Display.qml (встроен inline) или как отдельный компонент.
// Полностью опирается на BlinkController.blinkState — нет своих таймеров.
//
// Правила видимости:
//   left  → turnLeft && !turnRight && blinkState
//   right → turnRight && !turnLeft && blinkState
//   hazard→ turnLeft && turnRight && blinkState
// =============================================================================

import QtQuick 2.15

Item {
    id: root

    // Левый поворотник
    Image {
        anchors.left:           parent.left
        anchors.verticalCenter: parent.verticalCenter
        width:  parent.height
        height: parent.height

        source:   "qrc:/assets/icons/turn_left.png"
        fillMode: Image.PreserveAspectFit
        smooth:   true

        visible: dataModel.turnLeft
        opacity: (dataModel.turnLeft && !dataModel.turnRight) || (dataModel.turnLeft && dataModel.turnRight)
                 ? BlinkController.blinkState
                 : 0.0
        Behavior on opacity { NumberAnimation { duration: 55 } }
    }

    // Аварийка (центр)
    Text {
        anchors.centerIn: parent
        text:           "⚠"
        font.pixelSize: parent.height * 0.85
        color:          "#FFCC00"

        visible: dataModel.turnLeft && dataModel.turnRight
        opacity: (dataModel.turnLeft && dataModel.turnRight)
                 ? BlinkController.blinkState
                 : 0.0
        Behavior on opacity { NumberAnimation { duration: 55 } }
    }

    // Правый поворотник
    Image {
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        width:  parent.height
        height: parent.height

        source:   "qrc:/assets/icons/turn_right.png"
        fillMode: Image.PreserveAspectFit
        smooth:   true

        visible: dataModel.turnRight
        opacity: (dataModel.turnRight && !dataModel.turnLeft) || (dataModel.turnLeft && dataModel.turnRight)
                 ? BlinkController.blinkState
                 : 0.0
        Behavior on opacity { NumberAnimation { duration: 55 } }
    }
}
