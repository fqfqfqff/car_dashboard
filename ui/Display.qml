pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    clip: true   // контент не выступает за границы

    readonly property var dm:  (typeof dataModel !== "undefined" && dataModel !== null) ? dataModel : null
    readonly property var sim: (typeof simulator  !== "undefined" && simulator  !== null) ? simulator : null

    property var  criticalLabels: []
    property bool hasCritical:    false
    // Насколько дисплей заходит под гаджи — за этим краем фон скрыт
    property real sideOverlap: 0

    readonly property color speedColor: {
        const s = root.dm ? root.dm.speed : 0
        if (s > 240) return "#FF3B30"
        if (s > 200) return "#FFB300"
        if (s > 150) return "#FFCC00"
        return "#EDF1F5"
    }

    // ── ФОН ──────────────────────────────────────────────────────────────────
    // Фон только в центральной видимой части (не под гаджами)
    Rectangle {
        x:      root.sideOverlap
        y:      0
        width:  root.width  - root.sideOverlap * 2
        height: root.height
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#181A1F" }
            GradientStop { position: 0.5; color: "#111317" }
            GradientStop { position: 1.0; color: "#0C0E12" }
        }
    }

    // Стеклянный блик
    Rectangle {
        x:      root.sideOverlap
        y:      0
        width:  root.width  - root.sideOverlap * 2
        height: root.height * 0.14
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2C3340" }
            GradientStop { position: 0.5; color: "#1A1E28" }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.50
    }

    // Верхняя граница (не доходит до краёв под гаджами)
    Rectangle {
        x:      root.sideOverlap
        y:      0
        width:  root.width  - root.sideOverlap * 2
        height: 1
        color:  "#4A5260"
        opacity: 0.75
    }

    // Нижняя граница
    Rectangle {
        x:      root.sideOverlap
        y:      root.height - 1
        width:  root.width  - root.sideOverlap * 2
        height: 1
        color:  "#3A424F"
        opacity: 0.55
    }

    // ── ШАПКА ────────────────────────────────────────────────────────────────
    Item {
        id: headerZone
        x:      root.sideOverlap
        y:      0
        width:  root.width  - root.sideOverlap * 2
        height: root.height * 0.20

        Text {
            anchors.left:           parent.left
            anchors.leftMargin:     parent.width * 0.08
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(new Date(), "hh:mm")
            font.family: "Microgramma"; font.pixelSize: root.height * 0.048
            color: "#C8CDD4"
            Timer { interval: 1000; running: true; repeat: true
                onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm") }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.32; height: root.height * 0.080
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.dm && root.dm.engineRunning ? "#17311D" : "#221316" }
                GradientStop { position: 1.0; color: root.dm && root.dm.engineRunning ? "#0C1710" : "#140C0E" }
            }
            border.width: 1
            border.color: root.dm && root.dm.engineRunning ? "#30D158" : "#4A2A2F"
            Text {
                anchors.centerIn: parent
                text: root.dm && root.dm.engineRunning ? "ENGINE ON" : "ENGINE OFF"
                font.family: "Microgramma"; font.pixelSize: root.height * 0.030
                color: root.dm && root.dm.engineRunning ? "#7EE39A" : "#8F6C71"
            }
        }

        Text {
            anchors.right:          parent.right
            anchors.rightMargin:    parent.width * 0.08
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(new Date(), "dd.MM")
            font.family: "Microgramma"; font.pixelSize: root.height * 0.048
            color: "#C8CDD4"
            Timer { interval: 60000; running: true; repeat: true
                onTriggered: parent.text = Qt.formatDate(new Date(), "dd.MM") }
        }
    }

    // Разделитель под шапкой
    Rectangle {
        x:      root.sideOverlap + (root.width - root.sideOverlap * 2) * 0.07
        y:      headerZone.y + headerZone.height
        width:  (root.width - root.sideOverlap * 2) * 0.86
        height: 1; color: "#242933"
    }

    // ── ЦЕНТРАЛЬНАЯ ЗОНА ──────────────────────────────────────────────────────
    Item {
        id: centerZone
        x:      root.sideOverlap
        y:      headerZone.height
        width:  root.width  - root.sideOverlap * 2
        height: root.height - headerZone.height - footerZone.height

        // Cruise badge
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: root.height * 0.018
            width: parent.width * 0.38; height: root.height * 0.066; radius: 8
            visible: root.dm ? root.dm.cruiseActive : false
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#15261C" }
                GradientStop { position: 1.0; color: "#0C1511" }
            }
            border.width: 1; border.color: "#2C4E39"
            Row {
                anchors.centerIn: parent; spacing: parent.width * 0.06
                Text { text: "CRUISE"; font.family: "Microgramma"; font.pixelSize: root.height * 0.024; color: "#77D596" }
                Text {
                    text: (root.sim && root.sim.cruiseTarget > 0) ? Math.round(root.sim.cruiseTarget) + " km/h" : "HOLD"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.024; color: "#B7F1C9"
                }
            }
        }

        // Скорость
        Column {
            anchors.centerIn: parent
            spacing: -root.height * 0.006
            opacity: root.hasCritical ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(root.dm ? root.dm.speed : 0).toString()
                font.family: "Microgramma"; font.pixelSize: root.height * 0.26
                color: root.speedColor; horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 250 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "KM/H"
                font.family: "Microgramma"; font.pixelSize: root.height * 0.030
                font.letterSpacing: 4.2; color: "#4B525D"
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Критическое предупреждение
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.86
            height: Math.min(critList.contentHeight + root.height * 0.10, parent.height * 0.88)
            radius: 14; visible: root.hasCritical
            opacity: root.hasCritical ? 1.0 : 0.0
            color: "#220908"; border.width: 1; border.color: "#A52A23"
            SequentialAnimation on opacity {
                running: root.hasCritical; loops: Animation.Infinite
                NumberAnimation { from: 1.0;  to: 0.45; duration: 500; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.45; to: 1.0;  duration: 500; easing.type: Easing.InOutQuad }
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.leftMargin: parent.radius; anchors.rightMargin: parent.radius
                height: 2; radius: 1; color: "#FF3B30"; opacity: 0.45
            }
            Image {
                anchors.top: parent.top; anchors.topMargin: root.height * 0.012
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.height * 0.042; height: width
                source: "qrc:/assets/icons/red_triangle.png"
                fillMode: Image.PreserveAspectFit; smooth: true; opacity: 0.78
            }
            ListView {
                id: critList
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: parent.right }
                anchors.topMargin: root.height * 0.075; anchors.bottomMargin: root.height * 0.020
                clip: true; spacing: root.height * 0.008
                model: root.criticalLabels
                delegate: Text {
                    width: critList.width; text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.034; color: "#FF6E64"
                }
            }
        }

        // Фары + поворотники внизу центра
        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: root.height * 0.14

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.leftMargin: parent.width * 0.07; anchors.rightMargin: parent.width * 0.07
                height: 1; color: "#242933"
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: root.height * 0.012
                spacing: parent.width * 0.05
                Image { width: root.height*0.050; height: width; source: "qrc:/assets/icons/low_beam.png";  fillMode: Image.PreserveAspectFit; visible: root.dm ? root.dm.lowBeam  : false }
                Image { width: root.height*0.050; height: width; source: "qrc:/assets/icons/high_beam.png"; fillMode: Image.PreserveAspectFit; visible: root.dm ? root.dm.highBeam : false }
                Image { width: root.height*0.050; height: width; source: "qrc:/assets/icons/fog.png";       fillMode: Image.PreserveAspectFit; visible: root.dm ? root.dm.fogLights: false }
            }
            TurnSignals {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                anchors.bottomMargin: root.height * 0.008
                anchors.leftMargin:   parent.width * 0.06
                anchors.rightMargin:  parent.width * 0.06
                height: parent.height * 0.45
            }
        }
    }

    // ── ПОДВАЛ ────────────────────────────────────────────────────────────────
    Item {
        id: footerZone
        x:      root.sideOverlap
        y:      root.height - height
        width:  root.width  - root.sideOverlap * 2
        height: root.height * 0.22

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: parent.width * 0.07; anchors.rightMargin: parent.width * 0.07
            height: 1; color: "#242933"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.07; anchors.rightMargin: parent.width * 0.07
            anchors.topMargin: root.height * 0.012; anchors.bottomMargin: root.height * 0.012
            spacing: parent.width * 0.04

            Column {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 2
                Text {
                    text: Math.round(root.dm ? root.dm.odometer : 0).toLocaleString(Qt.locale("en_US"), "f", 0)
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.052; color: "#C7CDD4"
                }
                Text { text: "ODO KM"; font.family: "Microgramma"; font.pixelSize: root.height * 0.020; color: "#4B525D" }
            }

            Column {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 5
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root.dm ? root.dm.engineTemp : 0) + "\u00B0"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.054
                    color: { const t = root.dm ? root.dm.engineTemp : 0; return t<60?"#4A8FD4":t<90?"#30D158":t<110?"#FFCC00":"#FF3B30" }
                }
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.parent.width * 0.60; height: root.height * 0.020
                    Rectangle { anchors.fill: parent; radius: height/2; color: "#0B0D11"; border.width: 1; border.color: "#232933" }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 2 }
                        radius: height / 2
                        readonly property real tempNorm: { const t = root.dm ? root.dm.engineTemp : 0; return t<=20?0.0:t>=130?1.0:(t-20.0)/110.0 }
                        width: Math.max(height - 2, (parent.width - 4) * tempNorm)
                        color: { const t = root.dm ? root.dm.engineTemp : 0; return t<60?"#4A8FD4":t<85?"#30D158":t<110?"#FFCC00":"#FF3B30" }
                        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation  { duration: 320 } }
                    }
                }
            }

            Column {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: 2
                Text {
                    anchors.right: parent.right
                    text: { if (!(root.dm && root.dm.engineRunning)) return "- - -"; return ((root.sim ? root.sim.fuelAvg : 0) > 0) ? (root.sim.fuelAvg).toFixed(1) : "0.0" }
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.052
                    color: { if (!(root.dm && root.dm.engineRunning)) return "#4B525D"; const f = root.sim ? root.sim.fuelAvg : 0; return f>15?"#FF3B30":f>10?"#FFCC00":"#C7CDD4" }
                }
                Text { anchors.right: parent.right; text: root.dm && root.dm.engineRunning ? "AVG L/100" : "FUEL AVG"; font.family: "Microgramma"; font.pixelSize: root.height * 0.020; color: "#4B525D" }
            }
        }
    }
}
