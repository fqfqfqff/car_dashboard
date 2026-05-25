// IndicatorLight.qml
import QtQuick 2.15

Item {
    id: root
    property bool   active:   false
    property color  lightColor: "#30D158"
    property string symbol:   "●"
    property bool   blink:    false
    property real   fontSize: 14

    width: 28; height: 28

    Text {
        anchors.centerIn: parent
        text: root.symbol
        font.pixelSize: root.fontSize
        font.family: "Barlow Condensed, Arial, sans-serif"
        font.bold: true
        color: root.lightColor
        opacity: {
            if (!root.active) return 0.08
            if (root.blink)   return blinkTimer.blinkOn ? 1.0 : 0.0
            return 1.0
        }
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }

    Timer {
        id: blinkTimer
        property bool blinkOn: true
        interval: 500; repeat: true
        running: root.active && root.blink
        onTriggered: blinkOn = !blinkOn
    }
}
