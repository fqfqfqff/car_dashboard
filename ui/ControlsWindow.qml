import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: controlsWin
    title: "Управление"
    width:  1100
    height: 260
    color:  "#06060C"
    flags:  Qt.Window | Qt.WindowStaysOnTopHint

    // Закрытие окна не завершает приложение
    onClosing: function(close) {
        close.accepted = false
        controlsWin.hide()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Строка 1: Педали + поворотники + аварийка
        Row {
            spacing: 10
            width: parent.width

            // ── СТАРТ / СТОП ──
            CtrlBtn {
                label: dataModel.engineRunning ? "■ СТОП" : "▶ СТАРТ"
                baseColor:   dataModel.engineRunning ? "#1A0000" : "#001A08"
                activeColor: dataModel.engineRunning ? "#FF3333" : "#00FF88"
                w: 140; h: 80
                onClicked: dataModel.engineRunning ? controller.stopEngine() : controller.startEngine()
            }

            Rectangle { width: 2; height: 80; color: "#14142A" }

            // ── ПЕДАЛИ ──
            CtrlBtn {
                label: "ГАЗ"
                baseColor: "#001A10"; activeColor: "#00FF88"
                w: 110; h: 80; pressable: true
                onPressed:  controller.setGas(1.0)
                onReleased: controller.setGas(0.0)
            }
            CtrlBtn {
                label: "ТОРМОЗ"
                baseColor: "#1A0000"; activeColor: "#FF3333"
                w: 110; h: 80; pressable: true
                onPressed:  controller.setBrake(1.0)
                onReleased: controller.setBrake(0.0)
            }
            CtrlBtn {
                label: "СЦЕПЛЕНИЕ"
                baseColor: "#0A0A1A"; activeColor: "#8888FF"
                w: 130; h: 80; pressable: true
                onPressed:  controller.setClutch(1.0)
                onReleased: controller.setClutch(0.0)
            }

            Rectangle { width: 2; height: 80; color: "#14142A" }

            // ── ПОВОРОТНИКИ ──
            CtrlBtn {
                label: "◄ ЛЕВ."
                baseColor: "#141000"; activeColor: "#FFD700"
                w: 110; h: 80
                onClicked: controller.setTurnLeft(!dataModel.turnLeft)
            }
            CtrlBtn {
                label: "АВАРИЙКА"
                baseColor: "#140800"; activeColor: "#FF6600"
                w: 120; h: 80
                onClicked: controller.setHazard(!(dataModel.turnLeft && dataModel.turnRight))
            }
            CtrlBtn {
                label: "ПРАВ. ►"
                baseColor: "#141000"; activeColor: "#FFD700"
                w: 110; h: 80
                onClicked: controller.setTurnRight(!dataModel.turnRight)
            }

            Rectangle { width: 2; height: 80; color: "#14142A" }

            // ── СВЕТ ──
            CtrlBtn {
                label: "БЛИЖНИЙ"
                baseColor: "#000E18"; activeColor: "#00BFFF"
                active: dataModel.lowBeam
                w: 120; h: 80
                onClicked: controller.setLowBeam(!dataModel.lowBeam)
            }
            CtrlBtn {
                label: "ДАЛЬНИЙ"
                baseColor: "#00041A"; activeColor: "#4488FF"
                active: dataModel.highBeam
                w: 120; h: 80
                onClicked: controller.setHighBeam(!dataModel.highBeam)
            }
            CtrlBtn {
                label: "ТУМАН"
                baseColor: "#001408"; activeColor: "#00FF88"
                active: dataModel.fogLights
                w: 100; h: 80
                onClicked: controller.setFogLights(!dataModel.fogLights)
            }

            Rectangle { width: 2; height: 80; color: "#14142A" }

            CtrlBtn {
                label: "КРУИЗ"
                baseColor: "#08001A"; activeColor: "#AA44FF"
                active: dataModel.cruiseActive
                w: 100; h: 80
                onClicked: controller.toggleCruise()
            }
        }
    }

    // ── Компонент кнопки ──
    component CtrlBtn: Item {
        id: cb
        property string label:       ""
        property color  baseColor:   "#0A0A18"
        property color  activeColor: "#00BFFF"
        property bool   pressable:   false
        property bool   active:      false
        property int    w:           110
        property int    h:           80

        signal clicked
        signal pressed
        signal released

        width: w; height: h

        // Синхронизация active с нажатием для pressable
        property bool _held: false
        property bool _on: active || _held

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: cb._on ? Qt.darker(cb.activeColor, 1.6) : cb.baseColor
            border.color: cb._on ? cb.activeColor : "#18182A"
            border.width: 2
            Behavior on color        { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }
        }

        // Glow
        Rectangle {
            anchors.fill: parent; radius: 10
            color: "transparent"
            border.color: cb.activeColor
            border.width: 1
            opacity: cb._on ? 0.45 : 0.0
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        Text {
            anchors.centerIn: parent
            text: cb.label
            font.family: "Microgramma"
            font.pixelSize: cb.h * 0.22
            font.weight:    Font.Normal
            font.letterSpacing: 1.0
            color: cb._on ? cb.activeColor : "#485060"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked:   cb.clicked()
            onPressed:   { if (cb.pressable) { cb._held = true;  cb.pressed()  } }
            onReleased:  { if (cb.pressable) { cb._held = false; cb.released() } }
        }
    }
}
