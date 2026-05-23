import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property var  criticalLabels: []
    property bool hasCritical:    false

    // ── ФОН ──────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 14
        color:  "#0A0A10"

        // Внешняя граница
        border.color: "#1A1A28"
        border.width: 1

        // Внутреннее свечение по краю
        Rectangle {
            anchors.fill:    parent
            anchors.margins: 1
            radius:          parent.radius - 1
            color:           "transparent"
            border.color:    "#0F0F1C"
            border.width:    1
        }
    }

    // Верхняя декоративная красная полоса (как в Granta FL)
    Rectangle {
        anchors.top:         parent.top
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.leftMargin:  parent.radius
        anchors.rightMargin: parent.radius
        height: root.height * 0.022
        radius: 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.12; color: "#FF3B30" }
            GradientStop { position: 0.88; color: "#FF3B30" }
            GradientStop { position: 1.0;  color: "transparent" }
        }
        opacity: 0.75
    }

    // Нижняя декоративная красная полоса
    Rectangle {
        anchors.bottom:      parent.bottom
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.leftMargin:  parent.radius
        anchors.rightMargin: parent.radius
        height: root.height * 0.022
        radius: 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.12; color: "#FF3B30" }
            GradientStop { position: 0.88; color: "#FF3B30" }
            GradientStop { position: 1.0;  color: "transparent" }
        }
        opacity: 0.75
    }

    // Горизонтальный разделитель под хедером
    Rectangle {
        id: headerDivider
        anchors.top:         headerZone.bottom
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.leftMargin:  parent.width * 0.06
        anchors.rightMargin: parent.width * 0.06
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.25; color: "#FF3B30" }
            GradientStop { position: 0.75; color: "#FF3B30" }
            GradientStop { position: 1.0;  color: "transparent" }
        }
        opacity: 0.35
    }

    // Горизонтальный разделитель над футером
    Rectangle {
        anchors.bottom:      footerZone.top
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.leftMargin:  parent.width * 0.06
        anchors.rightMargin: parent.width * 0.06
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.25; color: "#FF3B30" }
            GradientStop { position: 0.75; color: "#FF3B30" }
            GradientStop { position: 1.0;  color: "transparent" }
        }
        opacity: 0.35
    }

    // ── HEADER ───────────────────────────────────────────────────────────────
    Item {
        id: headerZone
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: root.height * 0.130

        // Время
        Text {
            id: clockText
            anchors.left:           parent.left
            anchors.leftMargin:     root.width * 0.07
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(new Date(), "hh:mm")
            font.family:        "Microgramma"
            font.pixelSize:     root.height * 0.040
            font.letterSpacing: 0.5
            color: "#C8C8D8"
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }

        // ENGINE статус (центр)
        Column {
            anchors.centerIn: parent
            spacing: 3

            // Статусная точка + текст
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Rectangle {
                    width:  root.height * 0.018
                    height: root.height * 0.018
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: dataModel.engineRunning ? "#30D158" : "#2A2A3A"
                    Behavior on color { ColorAnimation { duration: 400 } }

                    // Пульсация при работе
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: dataModel.engineRunning
                        NumberAnimation { to: 0.4; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                        onStopped: parent.opacity = 1.0
                    }
                }

                Text {
                    text: dataModel.engineRunning ? "ENGINE ON" : "ENGINE OFF"
                    font.family:        "Microgramma"
                    font.pixelSize:     root.height * 0.032
                    font.letterSpacing: 0.5
                    color: dataModel.engineRunning ? "#30D158" : "#2E2E40"
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
            }
        }

        // Дата
        Text {
            id: dateText
            anchors.right:          parent.right
            anchors.rightMargin:    root.width * 0.07
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(new Date(), "dd.MM")
            font.family:        "Microgramma"
            font.pixelSize:     root.height * 0.040
            font.letterSpacing: 0.5
            color: "#C8C8D8"
            Timer {
                interval: 60000; running: true; repeat: true
                onTriggered: dateText.text = Qt.formatDate(new Date(), "dd.MM")
            }
        }
    }

    // ── CENTER ───────────────────────────────────────────────────────────────
    Item {
        id: centerZone
        anchors.top:          headerZone.bottom
        anchors.bottom:       footerZone.top
        anchors.left:         parent.left
        anchors.right:        parent.right
        anchors.topMargin:    root.height * 0.006
        anchors.bottomMargin: root.height * 0.006

        // ── Скорость крупно ──────────────────────────────────────────────────
        Text {
            id: speedText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            anchors.verticalCenterOffset: -root.height * 0.024

            text: Math.round(dataModel.speed).toString()
            font.family:    "Microgramma"
            font.pixelSize: root.height * 0.200
            font.weight:    Font.Bold

            color: {
                const s = dataModel.speed
                if (s > 240) return "#FF3B30"
                if (s > 200) return "#FFB300"
                if (s > 150) return "#FFCC00"
                return "#FFFFFF"
            }
            Behavior on color { ColorAnimation { duration: 350 } }

            opacity: root.hasCritical ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }

        // km/h подпись
        Text {
            anchors.top:              speedText.bottom
            anchors.topMargin:        -root.height * 0.006
            anchors.horizontalCenter: parent.horizontalCenter
            text:               "km/h"
            font.family:        "Microgramma"
            font.pixelSize:     root.height * 0.030
            font.letterSpacing: 4.5
            color:              "#252535"
            opacity: root.hasCritical ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }

        // Круиз-контроль
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              speedText.top
            anchors.topMargin:        -root.height * 0.048
            spacing: 8
            opacity: (dataModel.cruiseActive && !root.hasCritical) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 280 } }

            Rectangle {
                width:  cruiseRow.implicitWidth + 20
                height: cruiseRow.implicitHeight + 10
                radius: height / 2
                color:  "#001A08"
                border.color: "#30D158"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: cruiseRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "CC"
                        font.family:        "Microgramma"
                        font.pixelSize:     root.height * 0.026
                        color:              "#30D158"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: {
                            if (typeof simulator !== "undefined" && simulator.cruiseTarget > 0)
                                return Math.round(simulator.cruiseTarget) + " km/h"
                            return ""
                        }
                        font.family:    "Microgramma"
                        font.pixelSize: root.height * 0.026
                        color:          "#50D888"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // ── Критические ошибки (перекрывает скорость) ────────────────────────
        Rectangle {
            id: critOverlay
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -root.height * 0.010
            width:  parent.width * 0.86
            height: Math.min(
                        critList.contentHeight + root.height * 0.090,
                        parent.height * 0.94
                    )
            radius: 10
            color:        Qt.rgba(0.90, 0.08, 0.04, 0.08)
            border.color: "#FF3B30"
            border.width: 1
            opacity: root.hasCritical ? 1.0 : 0.0
            visible: opacity > 0.01

            SequentialAnimation {
                loops: Animation.Infinite
                running: root.hasCritical
                NumberAnimation { target: critOverlay; property: "opacity"; from: 1.0; to: 0.28; duration: 480; easing.type: Easing.InOutQuad }
                NumberAnimation { target: critOverlay; property: "opacity"; from: 0.28; to: 1.0; duration: 480; easing.type: Easing.InOutQuad }
            }

            Rectangle {
                anchors.top:         parent.top
                anchors.left:        parent.left
                anchors.right:       parent.right
                anchors.leftMargin:  parent.radius
                anchors.rightMargin: parent.radius
                height: 2; radius: 1
                color: "#FF3B30"; opacity: 0.50
            }

            Text {
                anchors.top:              parent.top
                anchors.topMargin:        root.height * 0.010
                anchors.horizontalCenter: parent.horizontalCenter
                text: "⚠"
                font.pixelSize: root.height * 0.042
                color: "#FF3B30"; opacity: 0.72
            }

            ListView {
                id: critList
                anchors.top:          parent.top
                anchors.topMargin:    root.height * 0.068
                anchors.bottom:       parent.bottom
                anchors.bottomMargin: root.height * 0.010
                anchors.left:         parent.left
                anchors.right:        parent.right
                clip: true
                model: root.criticalLabels
                spacing: root.height * 0.005

                delegate: Text {
                    width: critList.width
                    horizontalAlignment: Text.AlignHCenter
                    text:               modelData
                    font.family:        "Microgramma"
                    font.pixelSize:     root.height * 0.036
                    font.letterSpacing: 1.2
                    color:              "#FF5A4E"
                }
            }
        }
    }

    // ── FOOTER ───────────────────────────────────────────────────────────────
    Item {
        id: footerZone
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height: root.height * 0.175

        // Пробег
        Column {
            anchors.left:           parent.left
            anchors.leftMargin:     root.width * 0.07
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: Math.round(dataModel.odometer).toLocaleString(Qt.locale("en_US"), "f", 0)
                font.family:    "Microgramma"
                font.pixelSize: root.height * 0.052
                color:          "#A8A8C0"
            }
            Text {
                text: "KM"
                font.family:        "Microgramma"
                font.pixelSize:     root.height * 0.020
                font.letterSpacing: 0.5
                color:              "#242436"
            }
        }

        // Температура (центр)
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(dataModel.engineTemp) + "°"
                font.family:    "Microgramma"
                font.pixelSize: root.height * 0.052
                font.weight:    Font.Bold
                color: _tempColor
                Behavior on color { ColorAnimation { duration: 500 } }

                readonly property color _tempColor: {
                    const t = dataModel.engineTemp
                    if (t < 60)  return "#4A8FD4"
                    if (t < 90)  return "#30D158"
                    if (t < 110) return "#FFCC00"
                    return "#FF3B30"
                }
            }

            // Температурный бар
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  root.width * 0.20
                height: root.height * 0.016

                Rectangle {
                    anchors.fill: parent; radius: height / 2
                    color: "#0C0C18"; border.color: "#181828"; border.width: 1
                }
                Rectangle {
                    anchors.left:    parent.left
                    anchors.top:     parent.top
                    anchors.bottom:  parent.bottom
                    anchors.margins: 2
                    radius: height / 2

                    readonly property real _norm: {
                        const t = dataModel.engineTemp
                        if (t <= 20)  return 0.0
                        if (t >= 130) return 1.0
                        return (t - 20.0) / 110.0
                    }
                    width: Math.max(radius * 2, (parent.width - 4) * _norm)
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }

                    color: {
                        const t = dataModel.engineTemp
                        if (t < 60)  return "#4A8FD4"
                        if (t < 85)  return "#30D158"
                        if (t < 110) return "#FFCC00"
                        return "#FF3B30"
                    }
                    Behavior on color { ColorAnimation { duration: 500 } }
                }

                // Маркер нормы 90°
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x:      parent.width * ((88.0 - 20.0) / 110.0) - 0.8
                    width:  1.5; height: parent.height * 0.72
                    color:  "#282840"; radius: 1
                }
            }
        }

        // Расход топлива
        Column {
            anchors.right:          parent.right
            anchors.rightMargin:    root.width * 0.07
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                anchors.right: parent.right
                text: {
                    if (!dataModel.engineRunning) return "- - -"
                    if (typeof simulator !== "undefined" && simulator.fuelAvg > 0)
                        return simulator.fuelAvg.toFixed(1)
                    return "0.0"
                }
                font.family:    "Microgramma"
                font.pixelSize: root.height * 0.052
                color: {
                    if (!dataModel.engineRunning) return "#222232"
                    const f = (typeof simulator !== "undefined") ? simulator.fuelAvg : 0
                    if (f > 15) return "#FF3B30"
                    if (f > 10) return "#FFCC00"
                    return "#A8A8C0"
                }
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            Text {
                anchors.right: parent.right
                text: !dataModel.engineRunning ? "РАСХОД" : "СР.Л/100"
                font.family:        "Microgramma"
                font.pixelSize:     root.height * 0.020
                font.letterSpacing: 0.3
                color:              "#242436"
            }
        }
    }
}
