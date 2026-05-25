// DashSlider.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: root
    property string labelText: ""
    property real   from:      0
    property real   to:        100
    property real   value:     0
    property real   stepSize:  1
    signal moved(real val)

    Label {
        text: root.labelText
        color: "#7A8AA0"
        font.pixelSize: 11
        Layout.preferredWidth: 140
    }
    Slider {
        id: sl
        Layout.fillWidth: true
        from:     root.from
        to:       root.to
        value:    root.value
        stepSize: root.stepSize
        background: Rectangle {
            x: sl.leftPadding; y: sl.topPadding + sl.availableHeight / 2 - 2
            width: sl.availableWidth; height: 4; radius: 2
            color: "#1A2030"
            Rectangle {
                width: sl.visualPosition * parent.width
                height: parent.height; radius: 2; color: "#4FA3D4"
            }
        }
        handle: Rectangle {
            x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
            y: sl.topPadding + sl.availableHeight / 2 - height / 2
            width: 14; height: 14; radius: 7
            color: "#E8EDF5"; border.color: "#4FA3D4"; border.width: 1
        }
        onMoved: root.moved(value)
    }
    Label {
        text: sl.value.toFixed(0)
        color: "#4FA3D4"
        font.pixelSize: 10
        font.family: "Share Tech Mono, monospace"
        Layout.preferredWidth: 40
    }
}
