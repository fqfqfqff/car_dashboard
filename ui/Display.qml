// =============================================================================
// Display.qml — Центральная информационная панель. Переработка v4.
//
// СТРУКТУРА:
//   ┌──────────────────────────────────────────────────┐
//   │  HEADER:  [hh:mm]   ENGINE ON/OFF   [dd.MM.yyyy] │
//   ├──────────────────────────────────────────────────┤
//   │  CENTER:  [скорость крупно]                      │
//   │           [передача / круиз]                     │
//   │  ── при критической ошибке: список ошибок ──     │
//   │  [поворотники]                                   │
//   ├──────────────────────────────────────────────────┤
//   │  FOOTER:  [ПРОБЕГ]  [ТЕМП °]  [РАСХОД л/100]    │
//   └──────────────────────────────────────────────────┘
//
// ИЗМЕНЕНИЯ vs. v3:
//   • Принимает criticalLabels и hasCritical из Dashboard (от IndicatorPanel)
//   • При hasCritical=true: скрывает скорость, показывает список ошибок
//   • headerZone height: 0.145 → 0.122 (чуть меньше)
//   • footerZone height: 0.190 → 0.168 (чуть меньше)
//   • Температурный бар тоньше (0.018)
// =============================================================================

import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    // Входные данные от Dashboard / IndicatorPanel
    property var  criticalLabels: []
    property bool hasCritical:    false

    // ── ФОН ─────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       16
        color:        "#0D0D0F"
        border.color: "#1C1C2A"
        border.width: 1
    }

    Rectangle {
        anchors.top:         parent.top
        anchors.topMargin:   1
        anchors.left:        parent.left
        anchors.leftMargin:  parent.width * 0.08
        anchors.right:       parent.right
        anchors.rightMargin: parent.width * 0.08
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: "#2A2A44" }
            GradientStop { position: 0.7; color: "#2A2A44" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ── HEADER ───────────────────────────────────────────────────────────────
    Item {
        id: headerZone
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: root.height * 0.122   // было 0.145

        Rectangle {
            anchors.bottom:      parent.bottom
            anchors.left:        parent.left
            anchors.leftMargin:  root.width * 0.06
            anchors.right:       parent.right
            anchors.rightMargin: root.width * 0.06
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: "#1E1E30" }
                GradientStop { position: 0.8; color: "#1E1E30" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ВРЕМЯ
        Column {
            anchors.left:           parent.left
            anchors.leftMargin:     root.width * 0.065
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: clockText
                text: Qt.formatTime(new Date(), "hh:mm")
                font.family:        "Microgramma"
                font.pixelSize:     root.height * 0.035
                font.weight:        Font.DemiBold
                font.letterSpacing: 0.2
                color:              "#D0D0E0"
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }
        }

        // Статус двигателя (центр хедера)
        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: dataModel.engineRunning ? "ENGINE ON" : "ENGINE OFF"
                font.family:        "Microgramma"
                font.pixelSize:     root.height * 0.028
                font.letterSpacing: 0.1
                color: dataModel.engineRunning ? "#30D158" : "#363640"
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }

        // ДАТА
        ColumnLayout {
            anchors.right:          parent.right
            anchors.rightMargin:    root.width * 0.065
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: dateText
                anchors.right: parent.right
                text: Qt.formatDate(new Date(), "dd.MM")
                font.family:        "Microgramma"
                font.pixelSize:     root.height * 0.035
                font.letterSpacing: 0.2
                color:              "#D0D0E0"
                Timer {
                    interval: 60000; running: true; repeat: true
                    onTriggered: dateText.text = Qt.formatDate(new Date(), "dd.MM")
                }
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
        anchors.topMargin:    root.height * 0.008
        anchors.bottomMargin: root.height * 0.008

        // ── НОРМАЛЬНЫЙ РЕЖИМ: скорость ────────────────────────────────────
        Text {
            id: speedText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            anchors.verticalCenterOffset: -root.height * 0.028

            text: Math.round(dataModel.speed).toString()
            font.family:    "Microgramma"
            font.pixelSize: root.height * 0.195
            font.weight:    Font.Bold
            // Цветовые зоны:
            //   0–dangerZone*0.85    → нейтральная (светло-серая)
            //   dangerZone*0.85–0.85 → переход к жёлтому
            //   >dangerZone          → красный (с миганием через dangerBlink)
            // !!! СИНХРОНИЗИРУЙ ЦВЕТА СКОРОСТИ С GAUGEITEM.CPP (СПИДОМЕТР) 140-179 строки

            color: {
                let s = dataModel.speed
                if (s > 240) return "#FF3B30"      // красный
                if (s > 200) return "#FFB300"      // оранжевый
                if (s > 150) return "#FFCC00"      // жёлтый
                return "#FFFFFF"                    // белый
            }
            Behavior on color { ColorAnimation { duration: 350 } }

            opacity: root.hasCritical ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        Text {
            anchors.top:              speedText.bottom
            anchors.topMargin:        -root.height * 0.005
            anchors.horizontalCenter: parent.horizontalCenter
            text:               "km/h"
            font.family:        "Microgramma"
            font.pixelSize:     root.height * 0.028
            font.letterSpacing: 4.0
            color:              "#34344A"
            opacity: root.hasCritical ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        // Передача + круиз
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.width * 0.050  // сдвиг вправо
            anchors.top:              speedText.top
            anchors.topMargin:        -root.height * 0.050      // выше
            spacing: root.width * 0.028
            opacity: root.hasCritical ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            // Item {
            //     width: gearLabel.width + gearValue.width + 8
            //     height: gearValue.height

            //     Text {
            //         id: gearLabel
            //         anchors.verticalCenter: parent.verticalCenter
            //         text: "GEAR"
            //         font.family:        "Microgramma"
            //         font.pixelSize:     root.height * 0.030
            //         font.letterSpacing: 0.5
            //         color:              "#2C2C3A"
            //     }
            //     Text {
            //         anchors.leftMargin:     8
            //         anchors.verticalCenter: parent.verticalCenter
            //         text: {
            //             if (!dataModel.engineRunning) return "P"
            //             if (dataModel.currentGear === 0) return "N"
            //             return dataModel.currentGear.toString()
            //         }
            //         font.family:    "Microgramma"
            //         font.pixelSize: root.height * 0.04
            //         color:          "#7070A0"
            //     }
            // }

            Row {
                spacing: 6
                opacity: dataModel.cruiseActive ? 1.0 : 0.0
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -root.width * 0.05  // сдвиг влево ширины
                anchors.verticalCenterOffset: -root.width * 0.16
                Behavior on opacity { NumberAnimation { duration: 300 } }

                Text {
                    text: "CRUISE CONTROL ON"
                    font.family:        "Microgramma"
                    font.pixelSize:     root.height * 0.024
                    font.letterSpacing: 0.2
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
                    font.pixelSize: root.height * 0.024
                    color:          "#50D080"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // ── КРИТИЧЕСКИЕ ОШИБКИ (перекрывает скорость) ────────────────────
        Rectangle {
            id: critOverlay
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -root.height * 0.012
            width:  parent.width * 0.84
            height: Math.min(
                        critList.contentHeight + root.height * 0.080,
                        parent.height * 0.95
                   )
            radius: 12
            color:        Qt.rgba(0.88, 0.08, 0.04, 0.10)
            border.color: "#FF3B30"
            border.width: 1

            opacity: root.hasCritical ? 1.0 : 0.0
            visible: opacity > 0.01

            // ── МИГАНИЕ ─────────────────────────────────────────────
            SequentialAnimation {
                id: critBlink
                loops: Animation.Infinite
                running: root.hasCritical
                NumberAnimation { target: critOverlay; property: "opacity"; from: 1.0; to: 0.3; duration: 500; easing.type: Easing.InOutQuad }
                NumberAnimation { target: critOverlay; property: "opacity"; from: 0.3; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
            }

            // Верхняя красная полоска
            Rectangle {
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.leftMargin:  parent.radius
                anchors.rightMargin: parent.radius
                height: 2
                radius: 1
                color: "#FF3B30"
                opacity: 0.45
            }

            // Иконка предупреждения
            Text {
                anchors.top:              parent.top
                anchors.topMargin:        root.height * 0.010
                anchors.horizontalCenter: parent.horizontalCenter
                text:               "⚠"
                font.pixelSize:     root.height * 0.040
                color:              "#FF3B30"
                opacity:            0.70
            }

            // Список критических ошибок
            ListView {
                id: critList
                anchors.top:         parent.top
                anchors.topMargin:   root.height * 0.065
                anchors.bottom:      parent.bottom
                anchors.bottomMargin: root.height * 0.010
                anchors.left:        parent.left
                anchors.right:       parent.right
                clip:     true
                model:    root.criticalLabels
                spacing:  root.height * 0.006

                delegate: Text {
                    width: critList.width
                    horizontalAlignment: Text.AlignHCenter
                    text:               modelData
                    font.family:        "Microgramma"
                    font.pixelSize:     root.height * 0.036
                    font.letterSpacing: 1.5
                    color:              "#FF5548"
                }
            }
        }

        // Поворотники
        Item {
            anchors.bottom:       parent.bottom
            anchors.left:         parent.left
            anchors.right:        parent.right
            height:               root.height * 0.088

            Rectangle {
                anchors.top:         parent.top
                anchors.left:        parent.left
                anchors.right:       parent.right
                anchors.leftMargin:  root.width * 0.05
                anchors.rightMargin: root.width * 0.05
                height: 1
                color: "#141520"
            }

            TurnSignals {
                id: turnSignals
                anchors.centerIn: parent
                width:  parent.width * 0.88
                height: parent.height * 0.74
            }

            Row {
                id: lightsRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: turnSignals.top
                anchors.bottomMargin: root.height * 0.025
                spacing: 12

                Image {
                    source: "qrc:/assets/icons/low_beam.png"
                    width: root.height * 0.06
                    height: width
                    visible: dataModel.lowBeam
                    fillMode: Image.PreserveAspectFit
                }

                Image {
                    source: "qrc:/assets/icons/high_beam.png"
                    width: root.height * 0.06
                    height: width
                    visible: dataModel.highBeam
                    fillMode: Image.PreserveAspectFit
                }

                Image {
                    source: "qrc:/assets/icons/fog.png"
                    width: root.height * 0.06
                    height: width
                    visible: dataModel.fogLights
                    fillMode: Image.PreserveAspectFit
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
        height: root.height * 0.168   // было 0.190

        Rectangle {
            anchors.top:         parent.top
            anchors.left:        parent.left
            anchors.leftMargin:  root.width * 0.06
            anchors.right:       parent.right
            anchors.rightMargin: root.width * 0.06
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: "#1A1A28" }
                GradientStop { position: 0.8; color: "#1A1A28" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ПРОБЕГ
        Column {
            anchors.left:           parent.left
            anchors.leftMargin:     root.width * 0.065
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: Math.round(dataModel.odometer).toLocaleString(Qt.locale("en_US"), "f", 0)
                font.family:    "Microgramma"
                font.pixelSize: root.height * 0.046
                font.weight:    Font.Normal
                color:          "#B0B0C8"
            }
            Text {
                text: "KM"
                font.family:        "Microgramma"
                font.pixelSize:     root.height * 0.017
                font.letterSpacing: 0.2
                color:              "#28283A"
            }
        }

        // ТЕМПЕРАТУРА (центр footer)
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            spacing: 3

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: root.width * 0.025
                text: Math.round(dataModel.engineTemp) + "°"
                font.family:    "Microgramma"
                font.pixelSize: root.height * 0.046
                font.weight:    Font.Bold
                color: tempColor
                Behavior on color { ColorAnimation { duration: 500 } }

                readonly property color tempColor: {
                    const t = dataModel.engineTemp
                    if (t < 60)  return "#4A8FD4"
                    if (t < 90)  return "#30D158"
                    if (t < 110) return "#FFCC00"
                    return "#FF3B30"
                }
            }

            // Температурный бар (тоньше)
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width:  root.width * 0.18
                height: root.height * 0.015  // было 0.024

                Rectangle {
                    anchors.fill: parent; radius: height / 2
                    color: "#0E0E16"; border.color: "#1C1C28"; border.width: 1
                }

                Rectangle {
                    anchors.left:    parent.left
                    anchors.top:     parent.top
                    anchors.bottom:  parent.bottom
                    anchors.margins: 2
                    radius: height / 2

                    readonly property real tempNorm: {
                        const t = dataModel.engineTemp
                        if (t <= 20)  return 0.0
                        if (t >= 130) return 1.0
                        return (t - 20.0) / 110.0
                    }
                    width: Math.max(radius * 2, (parent.width - 4) * tempNorm)
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }

                    readonly property color tc: {
                        const t = dataModel.engineTemp
                        if (t < 60)  return "#4A8FD4"
                        if (t < 85)  return "#30D158"
                        if (t < 110) return "#FFCC00"
                        return "#FF3B30"
                    }
                    color: tc
                    Behavior on color { ColorAnimation { duration: 500 } }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * ((88.0 - 20.0) / 110.0) - 0.5
                    width: 1.5; height: parent.height * 0.70
                    color: "#2A2A3C"; radius: 1
                }
            }

            // Text {
            //     anchors.horizontalCenter: parent.horizontalCenter
            //     text: "ТЕМПЕРАТУРА ДВС"
            //     font.family:        "Microgramma"
            //     font.pixelSize:     root.height * 0.016
            //     font.letterSpacing: 0.2
            //     color:              "#1E1E2A"   // еле видная
            // }
        }

        // РАСХОД ТОПЛИВА
        Column {
            anchors.right:          parent.right
            anchors.rightMargin:    root.width * 0.065
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                anchors.right: parent.right
                text: {
                    if (!dataModel.engineRunning) return "- - -"
                    if (typeof simulator !== "undefined" && simulator.fuelAvg > 0)
                        return simulator.fuelAvg.toFixed(1)
                    return "0.0"
                }
                font.family:    "Microgramma"
                font.pixelSize: root.height * 0.046
                font.weight:    Font.Normal
                color: {
                    if (!dataModel.engineRunning) return "#2C2C3A"
                    const f = (typeof simulator !== "undefined") ? simulator.fuelAvg : 0
                    if (f > 15) return "#FF3B30"
                    if (f > 10) return "#FFCC00"
                    return "#B0B0C8"
                }
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            Text {
                anchors.right: parent.right
                text: !dataModel.engineRunning ? "РАСХОД" : "СР.Л/100 КМ"
                font.family:        "Microgramma"
                font.pixelSize:     root.height * 0.017
                font.letterSpacing: 0.2
                color:              "#28283A"
            }
        }
    }
}
