pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    clip: true

    readonly property var dm:  (typeof dataModel !== "undefined" && dataModel !== null) ? dataModel : null
    readonly property var sim: (typeof simulator  !== "undefined" && simulator  !== null) ? simulator : null

    property var  criticalLabels: []
    property bool hasCritical:    false
    property real sideOverlap: 0
    property real gaugeR: 0

    readonly property color speedColor: {
        var s = root.dm ? root.dm.speed : 0
        if (s > 240) return "#FF3B30"
        if (s > 200) return "#FFB300"
        if (s > 150) return "#FFCC00"
        return "#EDF1F5"
    }

    // ── ФОН: Canvas с боковыми дугами формы гаджей ───────────────────────────
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        z: 0

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var gr = root.gaugeR
            var w  = width, h = height

            if (gr < 10) {
                var sg = ctx.createLinearGradient(0, 0, 0, h)
                sg.addColorStop(0.0, "#161A22"); sg.addColorStop(1.0, "#0A0C12")
                ctx.fillStyle = sg; ctx.fillRect(0, 0, w, h); return
            }

            // Display начинается точно на внутреннем крае гаджей.
            // Центры дуг гаджей в локальных координатах Display:
            //   левый:  lCx = -gr  (центр гаджа слева за краем canvas)
            //   правый: rCx = w+gr (центр гаджа справа за краем canvas)
            var lCx = -gr
            var rCx = w + gr

            // Вертикальный центр гаджа в координатах Display.
            // Display.height = gaugeSize*(1 - 2*0.085), gaugeSize = 2*gr
            // Display.y = gaugeCY - gr + displayPadV = gaugeCY - gr + 2*gr*0.085
            // gaugeCYlocal = gaugeCY - Display.y = gr - 2*gr*0.085 = gr*(1 - 0.17)
            var gaugeCYlocal = gr * 0.83

            var dyTop = gaugeCYlocal
            var dyBot = h - gaugeCYlocal
            var sinTop = Math.min(0.9999, dyTop / gr)
            var sinBot = Math.min(0.9999, dyBot / gr)

            var rAngleTop = Math.PI - Math.asin(sinTop)
            var rAngleBot = Math.PI + Math.asin(sinBot)
            var lAngleBot = -Math.asin(sinBot)
            var lAngleTop =  Math.asin(sinTop)

            // Контур панели
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(w, 0)
            ctx.arc(rCx, gaugeCYlocal, gr, rAngleTop, rAngleBot, false)
            ctx.lineTo(0, h)
            ctx.arc(lCx, gaugeCYlocal, gr, lAngleBot, lAngleTop, false)
            ctx.closePath()

            // Слой 1: основной фон
            var bg = ctx.createLinearGradient(0, 0, 0, h)
            bg.addColorStop(0.00, "#171B24")
            bg.addColorStop(0.35, "#111418")
            bg.addColorStop(0.65, "#0E1016")
            bg.addColorStop(1.00, "#090C11")
            ctx.fillStyle = bg; ctx.fill()

            // Слой 2: стеклянный блик сверху
            ctx.save(); ctx.clip()
            var hiGrd = ctx.createLinearGradient(0, 0, 0, h * 0.22)
            hiGrd.addColorStop(0.0, "rgba(50,62,82,0.42)")
            hiGrd.addColorStop(0.6, "rgba(30,38,52,0.12)")
            hiGrd.addColorStop(1.0, "rgba(0,0,0,0.00)")
            ctx.fillStyle = hiGrd; ctx.fillRect(0, 0, w, h * 0.22)

            // Слой 3: тонкое затемнение снизу
            var botGrd = ctx.createLinearGradient(0, h * 0.80, 0, h)
            botGrd.addColorStop(0.0, "rgba(0,0,0,0.00)")
            botGrd.addColorStop(1.0, "rgba(0,0,0,0.15)")
            ctx.fillStyle = botGrd; ctx.fillRect(0, h * 0.80, w, h * 0.20)
            ctx.restore()

            // Верхняя рамка
            ctx.strokeStyle = "rgba(80,95,115,0.75)"
            ctx.lineWidth = 1.0
            ctx.beginPath(); ctx.moveTo(2, 0); ctx.lineTo(w - 2, 0); ctx.stroke()

            // Нижняя рамка
            ctx.strokeStyle = "rgba(50,60,75,0.50)"
            ctx.lineWidth = 1.0
            ctx.beginPath(); ctx.moveTo(2, h); ctx.lineTo(w - 2, h); ctx.stroke()

            // Боковые дуги — тонкая рамка
            ctx.strokeStyle = "rgba(65,78,96,0.55)"
            ctx.lineWidth = 1.0
            ctx.beginPath()
            ctx.arc(rCx, gaugeCYlocal, gr - 0.5, rAngleTop, rAngleBot, false)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(lCx, gaugeCYlocal, gr - 0.5, lAngleBot, lAngleTop, false)
            ctx.stroke()
        }

        Connections {
            target: root
            function onGaugeRChanged()      { bgCanvas.requestPaint() }
            function onSideOverlapChanged() { bgCanvas.requestPaint() }
            function onWidthChanged()       { bgCanvas.requestPaint() }
            function onHeightChanged()      { bgCanvas.requestPaint() }
        }
    }

    // ── КОНТЕНТНАЯ ЗОНА ───────────────────────────────────────────────────────
    Item {
        id: content
        anchors {
            fill:        parent
            leftMargin:  root.width * 0.04
            rightMargin: root.width * 0.04
        }
        clip: true
        z: 1

        // ── ШАПКА ────────────────────────────────────────────────────────────
        Item {
            id: headerZone
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.height * 0.195

            // Тонкий разделитель шапки
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right
                          leftMargin: parent.width*0.04; rightMargin: parent.width*0.04 }
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: "#2A3040" }
                    GradientStop { position: 0.7; color: "#2A3040" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Время — слева
            Column {
                anchors { left: parent.left; leftMargin: parent.width*0.06
                          verticalCenter: parent.verticalCenter }
                spacing: 1
                Text {
                    id: clockTxt
                    text: Qt.formatTime(new Date(), "hh:mm")
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.050
                    color: "#CBD2DC"
                    Timer { interval: 1000; running: true; repeat: true
                        onTriggered: clockTxt.text = Qt.formatTime(new Date(), "hh:mm") }
                }
                Text {
                    text: Qt.formatDate(new Date(), "ddd").toUpperCase()
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                    color: "#485060"; font.letterSpacing: 2.0
                }
            }

            // ENGINE STATUS badge — центр
            Item {
                anchors.centerIn: parent
                width: parent.width * 0.36; height: root.height * 0.080

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: root.dm && root.dm.engineRunning ? "#0E1E13" : "#160B0D"
                    border.width: 1
                    border.color: root.dm && root.dm.engineRunning ? "#2A6640" : "#3D1E24"
                    Behavior on border.color { ColorAnimation { duration: 600; easing.type: Easing.InOutQuad } }
                    Behavior on color        { ColorAnimation { duration: 600; easing.type: Easing.InOutQuad } }

                    Rectangle {
                        anchors { fill: parent; margins: 1 }
                        radius: parent.radius - 1
                        color: "transparent"
                        border.width: 1
                        border.color: root.dm && root.dm.engineRunning
                                      ? Qt.rgba(48/255, 209/255, 88/255, 0.18) : Qt.rgba(180/255, 60/255, 70/255, 0.12)
                        Behavior on border.color { ColorAnimation { duration: 600; easing.type: Easing.InOutQuad } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.dm && root.dm.engineRunning ? "ENGINE ON" : "ENGINE OFF"
                        font.family: "Microgramma"; font.pixelSize: root.height * 0.026
                        font.letterSpacing: 1.5
                        color: root.dm && root.dm.engineRunning ? "#5ED882" : "#8A5560"
                        Behavior on color { ColorAnimation { duration: 600; easing.type: Easing.InOutQuad } }
                    }
                }
            }

            // Дата — справа
            Column {
                anchors { right: parent.right; rightMargin: parent.width*0.06
                          verticalCenter: parent.verticalCenter }
                spacing: 1
                Text {
                    id: dateTxt
                    anchors.right: parent.right
                    text: Qt.formatDate(new Date(), "dd.MM")
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.050
                    color: "#CBD2DC"
                    Timer { interval: 60000; running: true; repeat: true
                        onTriggered: dateTxt.text = Qt.formatDate(new Date(), "dd.MM") }
                }
                Text {
                    anchors.right: parent.right
                    text: Qt.formatDate(new Date(), "yyyy")
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                    color: "#485060"; font.letterSpacing: 1.5
                }
            }
        }

        // ── ЦЕНТРАЛЬНАЯ ЗОНА ──────────────────────────────────────────────────
        Item {
            id: centerZone
            anchors {
                left: parent.left; right: parent.right
                top: headerZone.bottom; bottom: footerZone.top
            }

            // Cruise badge
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: root.height * 0.012
                width: parent.width * 0.38; height: root.height * 0.058; radius: 8
                visible: root.dm ? root.dm.cruiseActive : false
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                color: "#0D1A12"
                border.width: 1; border.color: "#224433"
                Row {
                    anchors.centerIn: parent; spacing: 10
                    Text { text: "CRUISE"; font.family: "Microgramma"
                           font.pixelSize: root.height * 0.020; color: "#6DC88A"; font.letterSpacing: 2 }
                    Text {
                        text: (root.sim && root.sim.cruiseTarget > 0)
                              ? Math.round(root.sim.cruiseTarget) + " km/h" : "HOLD"
                        font.family: "Microgramma"; font.pixelSize: root.height * 0.020
                        color: "#A8E8BC"; font.letterSpacing: 1
                    }
                }
            }

            // Скорость — основной элемент
            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -root.height * 0.008
                spacing: -root.height * 0.005
                opacity: root.hasCritical ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root.dm ? root.dm.speed : 0).toString()
                    font.family: "Microgramma"
                    font.pixelSize: root.height * 0.255
                    color: root.speedColor
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.InOutQuad } }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "KM / H"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.026
                    font.letterSpacing: 5.0; color: "#3A4252"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Критическое предупреждение
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.82
                height: Math.min(critList.contentHeight + root.height * 0.09, parent.height * 0.82)
                radius: 12
                visible: root.hasCritical
                opacity: root.hasCritical ? 1.0 : 0.0
                color: "#1C0706"; border.width: 1; border.color: "#882018"

                SequentialAnimation on opacity {
                    running: root.hasCritical; loops: Animation.Infinite
                    NumberAnimation { from: 1.0;  to: 0.40; duration: 550; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.40; to: 1.0;  duration: 550; easing.type: Easing.InOutQuad }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    anchors.margins: parent.radius; height: 1
                    color: "#FF3B30"; opacity: 0.30
                }

                Image {
                    anchors.top: parent.top; anchors.topMargin: root.height * 0.010
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.height * 0.038; height: width
                    source: "qrc:/assets/icons/red_triangle.png"
                    fillMode: Image.PreserveAspectFit; smooth: true; opacity: 0.80
                }

                ListView {
                    id: critList
                    anchors { top: parent.top; bottom: parent.bottom
                              left: parent.left; right: parent.right }
                    anchors.topMargin: root.height * 0.068
                    anchors.bottomMargin: root.height * 0.016
                    clip: true; spacing: root.height * 0.006
                    model: root.criticalLabels
                    delegate: Text {
                        required property string modelData
                        width: critList.width; text: modelData
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "Microgramma"
                        font.pixelSize: root.height * 0.030
                        font.letterSpacing: 1.5
                        color: "#FF7068"
                    }
                }
            }

            // Фары + поворотники
            Item {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: root.height * 0.13

                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    anchors.leftMargin: parent.width*0.06; anchors.rightMargin: parent.width*0.06
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: "#242933" }
                        GradientStop { position: 0.8; color: "#242933" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: root.height * 0.010
                    spacing: parent.width * 0.04
                    Image { width: root.height*0.044; height: width
                            source: "qrc:/assets/icons/low_beam.png"
                            fillMode: Image.PreserveAspectFit
                            visible: root.dm ? root.dm.lowBeam  : false }
                    Image { width: root.height*0.044; height: width
                            source: "qrc:/assets/icons/high_beam.png"
                            fillMode: Image.PreserveAspectFit
                            visible: root.dm ? root.dm.highBeam : false }
                    Image { width: root.height*0.044; height: width
                            source: "qrc:/assets/icons/fog.png"
                            fillMode: Image.PreserveAspectFit
                            visible: root.dm ? root.dm.fogLights: false }
                }

                TurnSignals {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    anchors.bottomMargin: root.height * 0.006
                    anchors.leftMargin:   parent.width * 0.05
                    anchors.rightMargin:  parent.width * 0.05
                    height: parent.height * 0.44
                }
            }
        }

        // ── ПОДВАЛ ───────────────────────────────────────────────────────────
        Item {
            id: footerZone
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: root.height * 0.215

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.leftMargin: parent.width*0.05; anchors.rightMargin: parent.width*0.05
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.15; color: "#222833" }
                    GradientStop { position: 0.85; color: "#222833" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin:   parent.width * 0.05
                anchors.rightMargin:  parent.width * 0.05
                anchors.topMargin:    root.height * 0.010
                anchors.bottomMargin: root.height * 0.010
                spacing: 0

                // ── ОДОМЕТР ──────────────────────────────────────────────────
                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    Text {
                        text: Math.round(root.dm ? root.dm.odometer : 0)
                                   .toLocaleString(Qt.locale("en_US"), "f", 0)
                        font.family: "Microgramma"
                        font.pixelSize: root.height * 0.052
                        color: "#C2CAD4"
                    }
                    Row {
                        spacing: 6
                        Rectangle { width: 8; height: 2; radius: 1; color: "#FF3B30"; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "ODO KM"
                            font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                            font.letterSpacing: 1.5; color: "#3E4858"
                        }
                    }
                }

                // Вертикальный разделитель
                Rectangle {
                    width: 1; Layout.fillHeight: true
                    Layout.topMargin: 8; Layout.bottomMargin: 8
                    color: "#1E2530"
                }

                // ── ТЕМПЕРАТУРА + БАР ─────────────────────────────────────────
                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 5

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(root.dm ? root.dm.engineTemp : 0) + "°"
                        font.family: "Microgramma"
                        font.pixelSize: root.height * 0.056
                        color: {
                            var t = root.dm ? root.dm.engineTemp : 0
                            return t < 60 ? "#4A8FD4" : t < 90 ? "#30D158" : t < 110 ? "#FFCC00" : "#FF3B30"
                        }
                        Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.InOutQuad } }
                    }

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.parent.width * 0.70
                        height: root.height * 0.022

                        Rectangle {
                            anchors.fill: parent; radius: height/2
                            color: "#0A0C10"
                            border.width: 1; border.color: "#1A2030"
                        }

                        Rectangle {
                            anchors { left: parent.left; top: parent.top
                                      bottom: parent.bottom; margins: 2 }
                            radius: height / 2
                            readonly property real tNorm: {
                                var t = root.dm ? root.dm.engineTemp : 0
                                return t <= 20 ? 0.0 : t >= 130 ? 1.0 : (t-20.0)/110.0
                            }
                            width: Math.max(height, (parent.width - 4) * tNorm)
                            color: {
                                var t = root.dm ? root.dm.engineTemp : 0
                                return t < 60 ? "#2A6AAA" : t < 85 ? "#1A8040" : t < 110 ? "#AA8800" : "#CC2A1A"
                            }
                            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.InOutQuad } }

                            Rectangle {
                                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 1 }
                                height: parent.height * 0.4; radius: height/2
                                color: Qt.rgba(1, 1, 1, 0.12)
                            }
                        }

                        Rectangle {
                            x: (parent.width - 4) * (70.0/110.0) + 2
                            anchors { top: parent.top; bottom: parent.bottom }
                            width: 1; color: Qt.rgba(48/255, 209/255, 88/255, 0.30)
                        }
                    }
                }

                // Вертикальный разделитель
                Rectangle {
                    width: 1; Layout.fillHeight: true
                    Layout.topMargin: 8; Layout.bottomMargin: 8
                    color: "#1E2530"
                }

                // ── РАСХОД ТОПЛИВА ────────────────────────────────────────────
                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: 3

                    Text {
                        anchors.right: parent.right
                        text: {
                            if (!(root.dm && root.dm.engineRunning)) return "– –"
                            var f = root.sim ? root.sim.fuelAvg : 0
                            return f > 0 ? f.toFixed(1) : "0.0"
                        }
                        font.family: "Microgramma"
                        font.pixelSize: root.height * 0.052
                        color: {
                            if (!(root.dm && root.dm.engineRunning)) return "#2E3848"
                            var f = root.sim ? root.sim.fuelAvg : 0
                            return f > 15 ? "#FF3B30" : f > 10 ? "#FFCC00" : "#C2CAD4"
                        }
                        Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.InOutQuad } }
                    }
                    Row {
                        anchors.right: parent.right
                        spacing: 6
                        Text {
                            text: root.dm && root.dm.engineRunning ? "AVG L/100" : "FUEL AVG"
                            font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                            font.letterSpacing: 1.5; color: "#3E4858"
                        }
                        Rectangle { width: 8; height: 2; radius: 1; color: "#4FA3D4"; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }
}
