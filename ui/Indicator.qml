import QtQuick 2.15
import QtQuick.Effects

Item {
    id: root

    property string iconSource: ""
    property string label:      ""
    property string state:      "off"

    width:  110
    height: 90

    readonly property color stateColor: {
        switch (root.state) {
            case "critical": return "#FF2222"
            case "warning":  return "#FFD700"
            case "info":     return "#00BFFF"
            default:         return "#252535"
        }
    }

    opacity: root.state === "off" ? 0.12 : 1.0
    Behavior on opacity {
        NumberAnimation { duration: 260; easing.type: Easing.InOutQuad }
    }

    SequentialAnimation on opacity {
        running: root.state === "critical"
        loops:   Animation.Infinite
        NumberAnimation { to: 0.12; duration: 420; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0;  duration: 420; easing.type: Easing.InOutSine }
        onStopped: root.opacity = (root.state === "off") ? 0.12 : 1.0
    }

    Column {
        anchors.centerIn: parent
        spacing: 6

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 50; height: 50

            Image {
                id: src
                anchors.fill: parent
                source: root.iconSource
                sourceSize: Qt.size(50, 50)
                visible: false
                smooth: true
            }

            MultiEffect {
                source: src
                anchors.fill: src
                colorization: 1.0
                colorizationColor: root.stateColor
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:  root.label
            font.family:      "microgrammanormal"
            font.pixelSize:   17
            font.letterSpacing: 1.0
            font.weight:      Font.Medium
            color: root.stateColor
        }
    }
}
