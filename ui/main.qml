import QtQuick 2.15
import QtQuick.Window 2.15
import "."

Window {
    id: root

    width: 3840
    height: 2160
    visible: true
    visibility: Qt.platform.os === "android" ? Window.FullScreen : Window.AutomaticVisibility
    flags: Qt.platform.os === "android"
           ? (Qt.Window | Qt.FramelessWindowHint)
           : Qt.Window
    title: "Car Dashboard"
    color: "#000000"

    FontLoader { source: "qrc:/assets/fonts/Microgramma-Normal.ttf" }
    FontLoader { source: "qrc:/assets/fonts/Inter-Regular.ttf" }
    FontLoader { source: "qrc:/assets/fonts/Inter-Bold.ttf" }
    FontLoader { source: "qrc:/assets/fonts/Inter-SemiBold.ttf" }

    Dashboard {
        anchors.fill: parent
    }
}
