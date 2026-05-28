// =============================================================================
// ControlsOverlay.qml — нижняя панель управления. v5.
// Добавлена кнопка CAN в стиле OvBtn.
// =============================================================================

import QtQuick 2.15

Item {
    id: root

    Rectangle {
        anchors.fill: parent; radius: 10
        color: "#0C0C0C"; border.color: "#1E1E1E"; border.width: 1
    }

    // ── РЯД 1: ОСНОВНОЕ УПРАВЛЕНИЕ ───────────────────────────────────────────
    Row {
        id: row1
        anchors.top:        parent.top
        anchors.topMargin:  parent.height * 0.090
        anchors.left:       parent.left
        anchors.leftMargin: parent.width * 0.008
        height: parent.height * 0.420
        spacing: parent.width * 0.005

        OvBtn { label: dataModel.engineRunning ? "■ СТОП" : "▶ СТАРТ"
            baseColor: dataModel.engineRunning ? "#0E0000" : "#000E06"
            activeColor: dataModel.engineRunning ? "#FF3B30" : "#30D158"
            forceActive: dataModel.engineRunning
            btnW: root.width * 0.065; btnH: parent.height
            onTriggered: dataModel.engineRunning ? controller.stopEngine() : controller.startEngine() }

        Div {}

        OvBtn { label: "ГАЗ"; baseColor: "#000E06"; activeColor: "#30D158"
            pressable: true; btnW: root.width * 0.048; btnH: parent.height
            onHeld: controller.setGas(1.0); onLetGo: controller.setGas(0.0) }
        OvBtn { label: "ТОРМОЗ"; baseColor: "#0E0000"; activeColor: "#FF3B30"
            pressable: true; btnW: root.width * 0.058; btnH: parent.height
            onHeld: controller.setBrake(1.0); onLetGo: controller.setBrake(0.0) }
        OvBtn { label: "СЦЕПЛ."; baseColor: "#060618"; activeColor: "#0A84FF"
            pressable: true; btnW: root.width * 0.058; btnH: parent.height
            onHeld: controller.setClutch(1.0); onLetGo: controller.setClutch(0.0) }

        Div {}

        OvBtn { label: "РУЧН."; baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.brakeSystem
            btnW: root.width * 0.044; btnH: parent.height
            onTriggered: controller.toggleHandbrake() }

        Div {}

        OvBtn { label: "◄ ЛЕВ."; baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.turnLeft && !dataModel.turnRight
            btnW: root.width * 0.050; btnH: parent.height
            onTriggered: controller.setTurnLeft(!dataModel.turnLeft) }
        OvBtn { label: "АВАР."; baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.turnLeft && dataModel.turnRight
            btnW: root.width * 0.044; btnH: parent.height
            onTriggered: controller.setHazard(!(dataModel.turnLeft && dataModel.turnRight)) }
        OvBtn { label: "ПРАВ. ►"; baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.turnRight && !dataModel.turnLeft
            btnW: root.width * 0.050; btnH: parent.height
            onTriggered: controller.setTurnRight(!dataModel.turnRight) }

        Div {}

        OvBtn { label: "БЛИЖН."; baseColor: "#00080E"; activeColor: "#0A84FF"
            forceActive: dataModel.lowBeam
            btnW: root.width * 0.052; btnH: parent.height
            onTriggered: controller.setLowBeam(!dataModel.lowBeam) }
        OvBtn { label: "ДАЛЬН."; baseColor: "#000418"; activeColor: "#4488FF"
            forceActive: dataModel.highBeam
            btnW: root.width * 0.052; btnH: parent.height
            onTriggered: controller.setHighBeam(!dataModel.highBeam) }
        OvBtn { label: "ТУМАН"; baseColor: "#000E06"; activeColor: "#30D158"
            forceActive: dataModel.fogLights
            btnW: root.width * 0.046; btnH: parent.height
            onTriggered: controller.setFogLights(!dataModel.fogLights) }

        Div {}

        OvBtn { label: "КРУИЗ"; baseColor: "#040018"; activeColor: "#30D158"
            forceActive: dataModel.cruiseActive
            btnW: root.width * 0.048; btnH: parent.height
            onTriggered: controller.toggleCruise() }

        OvBtn { label: "ПОЛОСА"; baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.laneAssist
            btnW: root.width * 0.052; btnH: parent.height
            onTriggered: controller.toggleLaneAssist() }
    }

    // ── РЯД 2: ТЕСТ-ИНДИКАТОРЫ + CAN ─────────────────────────────────────────
    Row {
        id: row2
        anchors.bottom:       parent.bottom
        anchors.bottomMargin: parent.height * 0.090
        anchors.left:         parent.left
        anchors.leftMargin:   parent.width * 0.008
        height: parent.height * 0.360
        spacing: parent.width * 0.004

        // CRITICAL
        OvBtn { label: "МАСЛО";  baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.oilPressure; btnW: root.width*0.046; btnH: parent.height
            onTriggered: controller.testOilPressure() }
        OvBtn { label: "ПЕРЕГР"; baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.overheating; btnW: root.width*0.050; btnH: parent.height
            onTriggered: controller.testOverheating() }
        OvBtn { label: "ТОРМОЗ"; baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.brakeSystem; btnW: root.width*0.052; btnH: parent.height
            onTriggered: controller.testBrakeSystem() }
        OvBtn { label: "АКБ";   baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.batteryFault; btnW: root.width*0.038; btnH: parent.height
            onTriggered: controller.testBattery() }
        OvBtn { label: "AIRBAG"; baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.airbagFault; btnW: root.width*0.054; btnH: parent.height
            onTriggered: controller.testAirbag() }
        OvBtn { label: "РЕМЕНЬ"; baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.seatbelt; btnW: root.width*0.052; btnH: parent.height
            onTriggered: controller.testSeatbelt() }
        OvBtn { label: "ЖИДК."; baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.brakeFluid; btnW: root.width*0.044; btnH: parent.height
            onTriggered: controller.testBrakeFluid() }
        OvBtn { label: "АКПП";  baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.transmissionFault; btnW: root.width*0.042; btnH: parent.height
            onTriggered: controller.testTransmissionFault() }
        OvBtn { label: "АКПП°"; baseColor: "#0E0000"; activeColor: "#FF3B30"
            forceActive: dataModel.transmissionOverheat; btnW: root.width*0.046; btnH: parent.height
            onTriggered: controller.testTransmissionOverheat() }

        Div {}

        // WARNING
        OvBtn { label: "CHECK"; baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.checkEngine; btnW: root.width*0.044; btnH: parent.height
            onTriggered: controller.testCheckEngine() }
        OvBtn { label: "ABS";   baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.absActive; btnW: root.width*0.036; btnH: parent.height
            onTriggered: controller.testAbs() }
        OvBtn { label: "ESP";   baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.espActive; btnW: root.width*0.036; btnH: parent.height
            onTriggered: controller.testEsp() }
        OvBtn { label: "TPMS";  baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.tpmsActive; btnW: root.width*0.038; btnH: parent.height
            onTriggered: controller.testTpms() }
        OvBtn { label: "ТОПЛ."; baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.fuelLow; btnW: root.width*0.046; btnH: parent.height
            onTriggered: controller.testFuelLow() }
        OvBtn { label: "КОЛОД."; baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.brakeWear; btnW: root.width*0.050; btnH: parent.height
            onTriggered: controller.testBrakeWear() }
        OvBtn { label: "РУЛЕВ."; baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.steeringFault; btnW: root.width*0.050; btnH: parent.height
            onTriggered: controller.testSteeringFault() }
        OvBtn { label: "ПРЕДУПР"; baseColor: "#0A0800"; activeColor: "#FFCC00"
            forceActive: dataModel.generalWarning; btnW: root.width*0.060; btnH: parent.height
            onTriggered: controller.testGeneralWarning() }

        Div {}

        // ── CAN-кнопка ────────────────────────────────────────────────────────
        // Зелёная когда подключён, синяя когда нет.
        // Статус отображается маленьким текстом под кнопкой.
        Item {
            width:  root.width * 0.055
            height: parent.height

            OvBtn {
                id: canBtn
                label:       canReader.connected ? "CAN ●" : "CAN ○"
                baseColor:   canReader.connected ? "#000E06" : "#00080E"
                activeColor: canReader.connected ? "#30D158" : "#0A84FF"
                forceActive: canReader.connected
                btnW: parent.width
                btnH: parent.height
                onTriggered: canReader.connected
                             ? canReader.disconnectDevice()
                             : canReader.connectDevice()
            }

            // Статус-строка под кнопкой (маленький шрифт)
            Text {
                anchors.top:              canBtn.bottom
                anchors.topMargin:        2
                anchors.horizontalCenter: parent.horizontalCenter
                text:    canReader.connected
                         ? canReader.statusText + "  [" + canReader.frameCount + " fr]"
                         : canReader.statusText
                font.family:    "Microgramma"
                font.pixelSize: 6
                color:   canReader.connected ? "#30D158" : "#383838"
                elide:   Text.ElideRight
                width:   parent.width
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ── Компонент кнопки ──────────────────────────────────────────────────────
    component OvBtn: Item {
        id: ob
        property string label:       ""
        property color  baseColor:   "#0A0A0A"
        property color  activeColor: "#0A84FF"
        property bool   pressable:   false
        property bool   forceActive: false
        property real   btnW:        100
        property real   btnH:        60
        signal triggered
        signal held
        signal letGo

        width: btnW; height: btnH
        property bool _held: false
        readonly property bool _on: forceActive || _held

        Rectangle {
            anchors.fill: parent; radius: 7
            color: ob._on ? Qt.darker(ob.activeColor, 2.4) : ob.baseColor
            border.color: ob._on ? Qt.rgba(ob.activeColor.r, ob.activeColor.g, ob.activeColor.b, 0.85) : "#262626"
            border.width: 1
            Behavior on color        { ColorAnimation { duration: 75 } }
            Behavior on border.color { ColorAnimation { duration: 75 } }
        }
        Text {
            anchors.centerIn: parent
            text: ob.label
            font.family: "Microgramma"; font.pixelSize: ob.btnH * 0.185
            font.letterSpacing: 0.3
            color: ob._on ? ob.activeColor : "#383838"
            Behavior on color { ColorAnimation { duration: 75 } }
        }
        MouseArea {
            anchors.fill: parent
            onClicked:  { if (!ob.pressable) ob.triggered() }
            onPressed:  { if ( ob.pressable) { ob._held = true;  ob.held()  } }
            onReleased: { if ( ob.pressable) { ob._held = false; ob.letGo() } }
        }
    }

    component Div: Rectangle {
        width: 1; height: parent.height * 0.44; color: "#1A1A1A"
        anchors.verticalCenter: parent !== null ? parent.verticalCenter : undefined
    }
}
