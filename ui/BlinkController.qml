pragma Singleton
import QtQuick 2.15

QtObject {
    id: root

    property bool blinkState: true

    readonly property bool blinkNeeded: dataModel.turnLeft || dataModel.turnRight

    readonly property bool showLeft:   dataModel.turnLeft  && blinkState
    readonly property bool showRight:  dataModel.turnRight && blinkState
    readonly property bool showHazard: dataModel.turnLeft  && dataModel.turnRight && blinkState

    property var _timer: Timer {
        interval: 500
        running:  root.blinkNeeded
        repeat:   true
        onTriggered: root.blinkState = !root.blinkState
        onRunningChanged: {
            if (!running) root.blinkState = true
        }
    }
}
