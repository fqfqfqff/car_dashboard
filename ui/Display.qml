import QtQuick 2.15

// =============================================================================
// Display.qml — центральная панель кластера.
//
// Раскладка «по краям» (заполняет всё пространство вогнутой формы):
//   • время — верхний левый угол, дата — верхний правый
//   • температура ДВС — под временем, запас хода — под датой
//   • центр — удержание в полосе (LKAS) ЛИБО ЭКО-эффективность (когда выкл)
//   • расход — нижний левый угол, пробег — нижний правый
//   • снизу — сегментная шкала топлива
//
// Производительность (важно для Android/CAN):
//   • данные только через dataModel/simulator (CAN пишет в dataModel)
//   • шкала топлива и ЭКО-блок — обычные Item/Rectangle (GPU-батчинг), без Canvas
//   • Canvas (дорога LKAS) перерисовывается только когда система активна
//   • края полос считаются по геометрии — пересчёт лишь при ресайзе
// =============================================================================

Item {
    id: root
    clip: false

    readonly property var dm:  (typeof dataModel !== "undefined" && dataModel !== null) ? dataModel : null
    readonly property var sim: (typeof simulator  !== "undefined" && simulator  !== null) ? simulator : null

    property var  criticalLabels: []
    property bool hasCritical:    false
    property real gaugeR: 0
    property real arcR:   0
    property real speedCXLocal: 0
    property real rpmCXLocal:   0
    property real gaugeCYLocal: 0

    readonly property real tankCapacity: 50.0
    readonly property real _padX: root.width * 0.022

    readonly property bool engineOn: root.dm ? root.dm.engineRunning : false
    readonly property bool lkActive: root.dm ? (root.dm.laneAssist && root.dm.engineRunning) : false

    readonly property real fuelLevel: root.dm ? root.dm.fuelLevel : 75
    readonly property real fuelNorm:  Math.max(0, Math.min(1, fuelLevel / 100.0))
    readonly property color fuelColor: {
        if (fuelLevel <= 8)  return "#FF3B30"
        if (fuelLevel <= 20) return "#FFB300"
        if (fuelLevel <= 40) return "#FFD24A"
        return "#E8EDF2"
    }

    readonly property color tempColor: {
        var t = root.dm ? root.dm.engineTemp : 20
        if (t >= 110) return "#FF3B30"
        if (t >= 95)  return "#FFCC00"
        if (t >= 60)  return "#30D158"
        return "#4A8FD4"
    }

    readonly property real rangeKm: {
        var avg = root.sim ? root.sim.fuelAvg : 0
        if (avg < 0.1 || fuelLevel <= 0) return 0
        return (fuelLevel / 100.0 * tankCapacity) / (avg / 100.0)
    }

    // ── Мгновенный расход и его трактовка (все случаи) ──────────────────────────
    readonly property real instL100: root.sim ? root.sim.fuelL100 : -1   // <0 = стоп/нет данных
    readonly property real instLph:  root.sim ? root.sim.fuelLph  : 0
    readonly property real speedKmh: root.dm ? root.dm.speed : 0

    // Текст значения расхода
    readonly property string consText: {
        if (!engineOn) return "—.—"
        if (speedKmh < 3.0) return instLph.toFixed(1)        // холостой ход → л/ч
        if (instL100 < 0)   return "0.0"
        return instL100.toFixed(1)
    }
    readonly property string consUnit: {
        if (!engineOn) return "л/100"
        if (speedKmh < 3.0) return "л/ч"
        return "л/100"
    }
    // Цвет расхода: высокий→красный, средний→жёлтый, низкий/накат→зелёный
    readonly property color consColor: {
        if (!engineOn) return "#2E3848"
        if (speedKmh < 3.0) return "#8FA0B5"                 // холостой — нейтральный
        var f = instL100 < 0 ? 0 : instL100
        if (f <= 0.2) return "#30D158"                       // накат — эко
        if (f <= 7.0) return "#7BD88A"
        if (f <= 13.0) return "#E8EDF2"
        if (f <= 18.0) return "#FFCC00"
        return "#FF3B30"
    }

    // ── ЭКО-эффективность (для центрального блока, когда LKAS выключен) ──────────
    readonly property int ecoScore: {
        if (!engineOn) return 0
        if (speedKmh < 3.0) return 60                        // холостой — нейтральный балл
        var f = instL100 < 0 ? 0 : instL100
        var s = 100.0 * (1.0 - Math.min(1.0, f / 18.0))
        return Math.round(Math.max(0, Math.min(100, s)))
    }
    function ecoColor(s) {
        if (s >= 75) return "#30D158"
        if (s >= 50) return "#9ACD32"
        if (s >= 30) return "#FFCC00"
        return "#FF3B30"
    }
    function ecoLabel(s) {
        if (!engineOn) return "—"
        if (speedKmh < 3.0) return "ХОЛОСТОЙ ХОД"
        if (s >= 75) return "ОТЛИЧНО"
        if (s >= 50) return "ХОРОШО"
        if (s >= 30) return "УМЕРЕННО"
        return "ВЫСОКИЙ РАСХОД"
    }

    // Края вогнутой фигуры на уровне y (локальные координаты)
    function shapeEdgesAtY(localY) {
        var d = localY - root.gaugeCYLocal
        var h = Math.sqrt(Math.max(0, root.arcR * root.arcR - d * d))
        return { leftX: root.speedCXLocal + h, rightX: root.rpmCXLocal - h }
    }
    function edgesAt(yFrac) { return shapeEdgesAtY(root.height * yFrac) }

    // ── Фон: чисто чёрная вогнутая фигура ──────────────────────────────────────
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        z: 0
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var lCX = root.speedCXLocal, rCX = root.rpmCXLocal
            var cy = root.gaugeCYLocal, R = root.arcR
            if (R < 10) return
            var topD = cy, botD = height - cy
            var rTopAngle = Math.atan2(-topD, -(Math.sqrt(Math.max(0, R*R - topD*topD))))
            var rBotAngle = Math.atan2( botD, -(Math.sqrt(Math.max(0, R*R - botD*botD))))
            var lBotAngle = Math.atan2( botD,  (Math.sqrt(Math.max(0, R*R - botD*botD))))
            var lTopAngle = Math.atan2(-topD,  (Math.sqrt(Math.max(0, R*R - topD*topD))))
            var topLeftX  = lCX + Math.sqrt(Math.max(0, R*R - topD*topD))
            var topRightX = rCX - Math.sqrt(Math.max(0, R*R - topD*topD))
            var botLeftX  = lCX + Math.sqrt(Math.max(0, R*R - botD*botD))
            ctx.beginPath()
            ctx.moveTo(topLeftX, 0); ctx.lineTo(topRightX, 0)
            ctx.arc(rCX, cy, R, rTopAngle, rBotAngle, true)
            ctx.lineTo(botLeftX, height)
            ctx.arc(lCX, cy, R, lBotAngle, lTopAngle, true)
            ctx.closePath()
            ctx.fillStyle = "#07080D"; ctx.fill()
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
    onArcRChanged:         bgCanvas.requestPaint()
    onSpeedCXLocalChanged: bgCanvas.requestPaint()
    onRpmCXLocalChanged:   bgCanvas.requestPaint()
    onGaugeCYLocalChanged: bgCanvas.requestPaint()

    // ════════════════════════════════════════════════════════════════════════
    // КОНТЕНТ
    // ════════════════════════════════════════════════════════════════════════
    Item {
        id: content
        anchors.fill: parent
        z: 1
        opacity: root.hasCritical ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        // ── Время (верхний левый угол) ──────────────────────────────────────
        Column {
            id: timeCol
            y: root.height * 0.040
            x: root.edgesAt(0.085).leftX + root._padX
            spacing: 0
            Text {
                id: clockTxt
                text: Qt.formatTime(new Date(), "HH:mm")
                font.family: "Microgramma"; font.pixelSize: root.height * 0.058
                color: "#D2D8E2"
                Timer { interval: 1000; running: true; repeat: true
                    onTriggered: clockTxt.text = Qt.formatTime(new Date(), "HH:mm") }
            }
            Text {
                text: Qt.formatDate(new Date(), "ddd").toUpperCase()
                font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                font.letterSpacing: 2.0; color: "#4A5468"
            }
        }

        // ── Дата (верхний правый угол) ──────────────────────────────────────
        Column {
            id: dateCol
            y: root.height * 0.040
            x: root.edgesAt(0.085).rightX - width - root._padX
            spacing: 0
            Text {
                id: dateTxt
                anchors.right: parent.right
                text: Qt.formatDate(new Date(), "dd.MM")
                font.family: "Microgramma"; font.pixelSize: root.height * 0.058
                color: "#D2D8E2"
                Timer { interval: 60000; running: true; repeat: true
                    onTriggered: dateTxt.text = Qt.formatDate(new Date(), "dd.MM") }
            }
            Text {
                anchors.right: parent.right
                text: Qt.formatDate(new Date(), "yyyy")
                font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                font.letterSpacing: 1.5; color: "#4A5468"
            }
        }

        // ── Иконки фар (верхний центр) ──────────────────────────────────────
        Row {
            y: root.height * 0.050
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.height * 0.030
            Image {
                width: root.height * 0.034; height: width
                source: "qrc:/assets/icons/low_beam.png"
                fillMode: Image.PreserveAspectFit; smooth: true
                visible: root.dm ? root.dm.lowBeam : false
            }
            Image {
                width: root.height * 0.034; height: width
                source: "qrc:/assets/icons/high_beam.png"
                fillMode: Image.PreserveAspectFit; smooth: true
                visible: root.dm ? root.dm.highBeam : false
            }
            Image {
                width: root.height * 0.034; height: width
                source: "qrc:/assets/icons/fog.png"
                fillMode: Image.PreserveAspectFit; smooth: true
                visible: root.dm ? root.dm.fogLights : false
            }
        }

        // ── Круиз-контроль (проработанный виджет, появляется при включении) ──
        Rectangle {
            id: cruiseWidget
            readonly property bool on: root.dm ? root.dm.cruiseActive : false
            readonly property int  setSpd: (root.sim && root.sim.cruiseTarget > 0) ? Math.round(root.sim.cruiseTarget) : 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.112
            width: cwRow.implicitWidth + root.height * 0.040
            height: root.height * 0.052
            radius: height / 2
            color: "#0A1A10"
            border.width: 1.4; border.color: "#2C6B3E"
            visible: opacity > 0.01
            opacity: on ? 1.0 : 0.0
            scale:   on ? 1.0 : 0.86
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutQuad } }
            Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

            // мягкое зелёное свечение рамки
            Rectangle {
                anchors.fill: parent; anchors.margins: -2; radius: parent.radius + 2
                color: "transparent"; border.width: 2; border.color: "#1E5A2C"; opacity: 0.5
            }

            Row {
                id: cwRow
                anchors.centerIn: parent
                spacing: root.height * 0.012
                // иконка круиза — кольцо со стрелкой стабилизации
                Canvas {
                    id: cwIcon
                    width: root.height * 0.030; height: width
                    anchors.verticalCenter: parent.verticalCenter
                    onWidthChanged: requestPaint()
                    onPaint: {
                        var c = getContext("2d"); c.clearRect(0,0,width,height)
                        var cx=width/2, cy=height/2, r=width*0.38
                        c.strokeStyle="#46C86A"; c.lineWidth=width*0.10; c.lineCap="round"
                        c.beginPath(); c.arc(cx,cy,r,Math.PI*0.75,Math.PI*2.25,false); c.stroke()
                        c.beginPath(); c.moveTo(cx-r*0.30,cy-r*0.50); c.lineTo(cx+r*0.45,cy); c.lineTo(cx-r*0.30,cy+r*0.50); c.stroke()
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 0
                    Text { text: "КРУИЗ-КОНТРОЛЬ"; font.family: "Microgramma"
                        font.pixelSize: root.height * 0.0125; font.letterSpacing: 1.4; color: "#6DC88A" }
                    Text { text: "АКТИВЕН"; font.family: "Microgramma"
                        font.pixelSize: root.height * 0.0105; font.letterSpacing: 1.0; color: "#3E6E4C" }
                }
                Rectangle { width: 1; height: root.height*0.030; color: "#23512F"; anchors.verticalCenter: parent.verticalCenter }
                Row {
                    anchors.verticalCenter: parent.verticalCenter; spacing: root.height*0.004
                    Text { text: cruiseWidget.setSpd > 0 ? cruiseWidget.setSpd : "—"
                        anchors.baseline: cwUnit.baseline
                        font.family: "Microgramma"; font.pixelSize: root.height * 0.034; color: "#C8F0D4" }
                    Text { id: cwUnit; text: "км/ч"; font.family: "Microgramma"
                        font.pixelSize: root.height * 0.015; color: "#4E7E5C" }
                }
            }
        }

        // ── Температура ДВС (под временем) ──────────────────────────────────
        Column {
            y: root.height * 0.150
            x: root.edgesAt(0.175).leftX + root._padX
            spacing: 1
            Text { text: "ТЕМП. ДВС"; font.family: "Microgramma"
                font.pixelSize: root.height * 0.016; font.letterSpacing: 1.4; color: "#3E4858" }
            Row {
                spacing: root.height * 0.004
                Text { text: Math.round(root.dm ? root.dm.engineTemp : 0)
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.034
                    color: root.tempColor
                    Behavior on color { ColorAnimation { duration: 500 } } }
                Text { anchors.baseline: parent.children[0].baseline
                    text: "°C"; font.pixelSize: root.height * 0.020; color: root.tempColor
                    Behavior on color { ColorAnimation { duration: 500 } } }
            }
        }

        // ── Запас хода (под датой) ──────────────────────────────────────────
        Column {
            y: root.height * 0.150
            x: root.edgesAt(0.175).rightX - width - root._padX
            spacing: 1
            Text { anchors.right: parent.right; text: "ЗАПАС ХОДА"; font.family: "Microgramma"
                font.pixelSize: root.height * 0.016; font.letterSpacing: 1.4; color: "#3E4858" }
            Text {
                anchors.right: parent.right
                text: {
                    if (!root.engineOn) return "—"
                    var r = root.rangeKm
                    return r > 0 ? "~" + Math.round(r) + " км" : "—"
                }
                font.family: "Microgramma"; font.pixelSize: root.height * 0.034
                color: {
                    var r = root.rangeKm
                    if (!root.engineOn || r <= 0) return "#3E4858"
                    if (r <= 50) return "#FF3B30"
                    if (r <= 100) return "#FFB300"
                    return "#AEB8C6"
                }
            }
        }

        // ════════════════════════════════════════════════════════════════════
        // ЦЕНТРАЛЬНАЯ ЗОНА — узкая часть фигуры
        // ════════════════════════════════════════════════════════════════════
        Item {
            id: centerArea
            readonly property var ce: root.edgesAt(0.5)
            x: ce.leftX + root._padX
            width: ce.rightX - ce.leftX - root._padX * 2
            y: root.height * 0.235
            height: root.height * 0.46

            // ── Заголовок зоны (меняется с режимом) ─────────────────────────
            Row {
                id: czTitle
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                spacing: root.height * 0.010
                Rectangle {   // пульсирующая точка статуса (только LKAS)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.lkActive
                    width: root.height*0.011; height: width; radius: width/2; color: "#FFCC00"
                    SequentialAnimation on opacity {
                        running: root.lkActive; loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.2; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.2; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.lkActive ? "РЕЖИМ УДЕРЖАНИЯ В ПОЛОСЕ АКТИВЕН" : "МОНИТОРИНГ АВТОМОБИЛЯ"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.019
                    font.letterSpacing: 2.2
                    color: root.lkActive ? "#FFD24A" : "#5A6B82"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            // ── Контейнер режимов с анимацией переключения ──────────────────
            Item {
                id: modeArea
                anchors { left: parent.left; right: parent.right; top: czTitle.bottom; bottom: parent.bottom
                          topMargin: root.height * 0.010 }

                // ═══ LKAS: дорога + острый полый жёлтый треугольник с тенью ═══
                Item {
                    id: laneWrap
                    anchors.fill: parent
                    visible: opacity > 0.01
                    opacity: root.lkActive ? 1.0 : 0.0
                    scale:   root.lkActive ? 1.0 : 0.93
                    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutQuad } }
                    Behavior on scale   { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

                    Canvas {
                        id: laneCanvas
                        anchors.fill: parent
                        property real phase: 0.0
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                            var w = width, h = height
                            if (w < 20 || h < 20) return
                            var vpX=w*0.5, vpY=h*0.04
                            var blX=w*0.05, brX=w*0.95, byY=h*0.99
                            var tlX=vpX-w*0.035, trX=vpX+w*0.035, tY=vpY

                            // эго-полоса
                            var grad = ctx.createLinearGradient(0, byY, 0, tY)
                            grad.addColorStop(0.0, "rgba(255,255,255,0.10)")
                            grad.addColorStop(0.55,"rgba(255,255,255,0.03)")
                            grad.addColorStop(1.0, "rgba(255,255,255,0.0)")
                            ctx.beginPath(); ctx.moveTo(blX,byY); ctx.lineTo(tlX,tY)
                            ctx.lineTo(trX,tY); ctx.lineTo(brX,byY); ctx.closePath()
                            ctx.fillStyle=grad; ctx.fill()

                            // бегущая разметка — эффект движения
                            var rungs=7
                            for (var i=0;i<rungs;i++){
                                var p=((i+phase)%rungs)/rungs
                                var t=Math.pow(p,2.3)
                                var ry=tY+(byY-tY)*t
                                var lx=tlX+(blX-tlX)*t, rx=trX+(brX-trX)*t
                                ctx.strokeStyle="rgba(210,220,235,"+(0.04+0.16*t).toFixed(3)+")"
                                ctx.lineWidth=0.8+1.4*t
                                ctx.beginPath(); ctx.moveTo(lx,ry); ctx.lineTo(rx,ry); ctx.stroke()
                            }

                            // белые границы полосы
                            function laneLine(x0,y0,x1,y1){
                                var ps=[[11,0.05],[6,0.12],[2.6,0.55],[1.2,0.98]]
                                ctx.lineCap="round"
                                for (var k=0;k<ps.length;k++){
                                    ctx.strokeStyle="rgba(255,255,255,"+ps[k][1]+")"
                                    ctx.lineWidth=ps[k][0]
                                    ctx.beginPath(); ctx.moveTo(x0,y0); ctx.lineTo(x1,y1); ctx.stroke()
                                }
                            }
                            laneLine(blX,byY,tlX,tY)
                            laneLine(brX,byY,trX,tY)

                            // ── машина: стрелка, ЛЕЖАЩАЯ на полосе (перспектива, наклон вперёд) ──
                            // проекция точки дороги: fx 0..1 поперёк полосы, dt 0(близко)..1(далеко)
                            function laneEdges(dt){ return [ blX+(tlX-blX)*dt, brX+(trX-brX)*dt ] }
                            function P(fx, dt){ var e=laneEdges(dt); return [ e[0]+fx*(e[1]-e[0]), byY+(tY-byY)*dt ] }
                            var mv = 0.012*Math.sin(phase*0.9)         // лёгкое «дыхание» движения
                            var dn = 0.20 + mv                          // ближний край (низ, широкий)
                            var df = 0.56 + mv                          // нос (вдаль/вперёд, узкий)
                            var pApex = P(0.50, df)                     // нос — наклонён вперёд (в перспективу)
                            var pBR   = P(0.73, dn)                     // задний правый
                            var pBL   = P(0.27, dn)                     // задний левый
                            var pN    = P(0.50, dn+0.10)                // задняя выемка (поднята к носу)
                            function carPath(ox,oy){
                                ctx.beginPath()
                                ctx.moveTo(pApex[0]+ox, pApex[1]+oy)
                                ctx.lineTo(pBR[0]+ox,  pBR[1]+oy)
                                ctx.lineTo(pN[0]+ox,   pN[1]+oy)
                                ctx.lineTo(pBL[0]+ox,  pBL[1]+oy)
                                ctx.closePath()
                            }
                            ctx.lineJoin = "miter"; ctx.miterLimit = 8; ctx.lineCap = "butt"  // ОСТРЫЕ углы
                            // тень на дороге (смещена к зрителю — объект лежит на полосе)
                            carPath(w*0.008, h*0.022); ctx.fillStyle="rgba(0,0,0,0.42)"; ctx.fill()
                            // свечение
                            var gp=[[14,0.05],[8,0.11]]
                            for (var gi=0; gi<gp.length; gi++){
                                carPath(0,0); ctx.strokeStyle="rgba(255,204,0,"+gp[gi][1]+")"
                                ctx.lineWidth=gp[gi][0]; ctx.stroke()
                            }
                            // полый: лёгкая внутренняя заливка
                            carPath(0,0); ctx.fillStyle="rgba(255,204,0,0.07)"; ctx.fill()
                            // широкая жёлтая грань с острыми углами
                            carPath(0,0); ctx.strokeStyle="rgba(255,214,40,0.98)"
                            ctx.lineWidth=Math.max(4, w*0.024); ctx.stroke()
                        }
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onPhaseChanged: requestPaint()
                        onVisibleChanged: if (visible) requestPaint()
                        Timer { interval: 60; repeat: true; running: root.lkActive
                            onTriggered: laneCanvas.phase = (laneCanvas.phase + 0.14) % 7 }
                    }
                }

                // ═══ Мониторинг авто (вид сверху + виталы) ═══
                Item {
                    id: monitorWrap
                    anchors.fill: parent
                    visible: opacity > 0.01
                    opacity: root.lkActive ? 0.0 : 1.0
                    scale:   root.lkActive ? 0.93 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.InOutQuad } }
                    Behavior on scale   { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

                    function tireColor(p) {
                        if (!root.engineOn || p <= 0) return "#39424F"
                        if (p < 1.8) return "#FF3B30"
                        if (p < 2.0 || p > 2.6) return "#FFCC00"
                        return "#30D158"
                    }

                    // схема автомобиля (вид сверху) — Canvas-модель
                    Item {
                        id: carDiag
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.0
                        width: parent.width * 0.30
                        height: parent.height * 0.82

                        Canvas {
                            id: carBodyCanvas
                            anchors.fill: parent
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onPaint: {
                                var c = getContext("2d"); c.clearRect(0,0,width,height)
                                var W = width, H = height; if (W < 10 || H < 10) return
                                var cx = W/2
                                var L0 = H*0.02, L1 = H*0.98
                                var maxHW = W*0.44

                                // профиль полуширины кузова: t∈[0..1] (0=нос, 1=корма)
                                function halfW(t){
                                    var rF = 0.16, rR = 0.18, k = 1.0
                                    if (t < rF)        k = Math.sqrt(Math.max(0, 1 - Math.pow((rF - t)/rF, 2)))
                                    else if (t > 1-rR) k = Math.sqrt(Math.max(0, 1 - Math.pow((t-(1-rR))/rR, 2)))
                                    var prof = (t < 0.28) ? 0.82 + 0.18*(t/0.28)
                                             : (t < 0.70) ? 1.0
                                             : 1.0 - 0.06*((t-0.70)/0.30)
                                    return maxHW * k * prof
                                }
                                function yAt(t){ return L0 + (L1 - L0) * t }
                                function bodyPath(){
                                    c.beginPath()
                                    var N = 48, i, t
                                    for (i = 0; i <= N; i++){ t = i/N; if (i===0) c.moveTo(cx+halfW(t), yAt(t)); else c.lineTo(cx+halfW(t), yAt(t)) }
                                    for (i = N; i >= 0; i--){ t = i/N; c.lineTo(cx-halfW(t), yAt(t)) }
                                    c.closePath()
                                }

                                // кузов — простая заливка + тонкий контур
                                bodyPath()
                                var bg = c.createLinearGradient(0, L0, 0, L1)
                                bg.addColorStop(0.0, "#333D4B"); bg.addColorStop(1.0, "#222A36")
                                c.fillStyle = bg; c.fill()
                                c.lineWidth = 2; c.strokeStyle = "rgba(150,166,186,0.55)"; c.stroke()

                                // только два стекла (лобовое и заднее), обрезаны по кузову
                                c.save(); bodyPath(); c.clip()
                                function glass(tT, tB, wT, wB){
                                    var yT = yAt(tT), yB = yAt(tB)
                                    c.beginPath(); c.moveTo(cx-wT,yT); c.lineTo(cx+wT,yT); c.lineTo(cx+wB,yB); c.lineTo(cx-wB,yB); c.closePath()
                                    c.fillStyle = "#121922"; c.fill()
                                }
                                glass(0.27, 0.42, W*0.17, W*0.30)   // лобовое
                                glass(0.60, 0.75, W*0.30, W*0.17)   // заднее
                                c.restore()
                            }
                        }

                        // колёса: шина (рамка = статус давления) + диск
                        component Wheel: Rectangle {
                            property real press: 0
                            width: carDiag.width*0.155; height: carDiag.height*0.175; radius: width*0.45
                            color: "#0A0D12"; border.width: 2.6
                            border.color: monitorWrap.tireColor(press)
                            Behavior on border.color { ColorAnimation { duration: 300 } }
                            Rectangle {  // диск
                                anchors.centerIn: parent
                                width: parent.width*0.56; height: parent.height*0.58; radius: width*0.5
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#3C4756" }
                                    GradientStop { position: 1.0; color: "#11151D" }
                                }
                                border.width: 1; border.color: "#454F5E"
                            }
                        }
                        Wheel { id: wFL; press: root.dm?root.dm.tirePressFL:0; x: carDiag.width*0.02; y: carDiag.height*0.15 }
                        Wheel { id: wFR; press: root.dm?root.dm.tirePressFR:0; x: carDiag.width*0.98 - width; y: wFL.y }
                        Wheel { id: wRL; press: root.dm?root.dm.tirePressRL:0; x: wFL.x; y: carDiag.height*0.76 }
                        Wheel { id: wRR; press: root.dm?root.dm.tirePressRR:0; x: wFR.x; y: wRL.y }

                        // значения давления
                        Text { anchors.right: wFL.left; anchors.rightMargin: carDiag.width*0.04; anchors.verticalCenter: wFL.verticalCenter
                            text: (root.dm?root.dm.tirePressFL:0).toFixed(1); font.family:"Microgramma"; font.pixelSize: root.height*0.021
                            color: monitorWrap.tireColor(root.dm?root.dm.tirePressFL:0) }
                        Text { anchors.left: wFR.right; anchors.leftMargin: carDiag.width*0.04; anchors.verticalCenter: wFR.verticalCenter
                            text: (root.dm?root.dm.tirePressFR:0).toFixed(1); font.family:"Microgramma"; font.pixelSize: root.height*0.021
                            color: monitorWrap.tireColor(root.dm?root.dm.tirePressFR:0) }
                        Text { anchors.right: wRL.left; anchors.rightMargin: carDiag.width*0.04; anchors.verticalCenter: wRL.verticalCenter
                            text: (root.dm?root.dm.tirePressRL:0).toFixed(1); font.family:"Microgramma"; font.pixelSize: root.height*0.021
                            color: monitorWrap.tireColor(root.dm?root.dm.tirePressRL:0) }
                        Text { anchors.left: wRR.right; anchors.leftMargin: carDiag.width*0.04; anchors.verticalCenter: wRR.verticalCenter
                            text: (root.dm?root.dm.tirePressRR:0).toFixed(1); font.family:"Microgramma"; font.pixelSize: root.height*0.021
                            color: monitorWrap.tireColor(root.dm?root.dm.tirePressRR:0) }
                    }

                    // виталы: масло / АКБ / охлаждение
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: parent.height*0.015
                        spacing: parent.width * 0.055

                        Column {
                            spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text:"МАСЛО"; font.family:"Microgramma"
                                font.pixelSize: root.height*0.014; font.letterSpacing:1.0; color:"#3E4858" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                text: !root.engineOn ? "—" : ((root.dm && root.dm.oilPressure) ? "СБОЙ" : "НОРМА")
                                font.family:"Microgramma"; font.pixelSize: root.height*0.023
                                color: !root.engineOn ? "#3E4858" : ((root.dm && root.dm.oilPressure) ? "#FF3B30" : "#30D158") }
                        }
                        Rectangle { width:1; height: root.height*0.05; color:"#1C2330"; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            id: battCol
                            spacing: 2
                            readonly property real volt: root.dm ? root.dm.batteryVoltage : 0
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text:"АКБ"; font.family:"Microgramma"
                                font.pixelSize: root.height*0.014; font.letterSpacing:1.0; color:"#3E4858" }
                            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: root.height*0.003
                                Text { text: battCol.volt.toFixed(1); font.family:"Microgramma"; font.pixelSize: root.height*0.023
                                    color: (root.dm && root.dm.batteryFault) ? "#FF3B30"
                                         : (battCol.volt>=13.0 ? "#30D158" : (battCol.volt>=11.8 ? "#C2CAD4" : "#FF3B30")) }
                                Text { anchors.baseline: parent.children[0].baseline; text:"В"; font.family:"Microgramma"
                                    font.pixelSize: root.height*0.015; color:"#48525F" } }
                        }
                        Rectangle { width:1; height: root.height*0.05; color:"#1C2330"; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text:"ОХЛ. ДВС"; font.family:"Microgramma"
                                font.pixelSize: root.height*0.014; font.letterSpacing:1.0; color:"#3E4858" }
                            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: root.height*0.003
                                Text { text: Math.round(root.dm?root.dm.engineTemp:0); font.family:"Microgramma"
                                    font.pixelSize: root.height*0.023; color: root.tempColor }
                                Text { anchors.baseline: parent.children[0].baseline; text:"°C"
                                    font.pixelSize: root.height*0.015; color: root.tempColor } }
                        }
                    }
                }
            }
        }

        // ── Расход (нижний левый угол) — все случаи ─────────────────────────
        Column {
            y: root.height * 0.735
            x: root.edgesAt(0.80).leftX + root._padX
            spacing: 1
            Text { text: "РАСХОД"; font.family: "Microgramma"
                font.pixelSize: root.height * 0.017; font.letterSpacing: 1.5; color: "#3E4858" }
            Row {
                spacing: root.height * 0.008
                Text { text: root.consText; font.family: "Microgramma"
                    font.pixelSize: root.height * 0.046; color: root.consColor
                    Behavior on color { ColorAnimation { duration: 400 } } }
                Text { anchors.baseline: parent.children[0].baseline
                    text: root.consUnit; font.family: "Microgramma"
                    font.pixelSize: root.height * 0.020; color: "#48525F" }
            }
            Text {
                text: {
                    if (!root.engineOn) return "СР  —.—"
                    var a = root.sim ? root.sim.fuelAvg : 0
                    return "СР  " + (a > 0 ? a.toFixed(1) : "0.0") + " л/100"
                }
                font.family: "Microgramma"; font.pixelSize: root.height * 0.016
                font.letterSpacing: 0.8; color: "#46505F"
            }
        }

        // ── Пробег (нижний правый угол) ─────────────────────────────────────
        Column {
            y: root.height * 0.735
            x: root.edgesAt(0.80).rightX - width - root._padX
            spacing: 1
            Text { anchors.right: parent.right; text: "ПРОБЕГ"; font.family: "Microgramma"
                font.pixelSize: root.height * 0.017; font.letterSpacing: 1.5; color: "#3E4858" }
            Row {
                anchors.right: parent.right; spacing: root.height * 0.008
                Text { text: { var km = Math.round(root.dm ? root.dm.odometer : 0)
                        return km.toLocaleString(Qt.locale("ru_RU"), "f", 0) }
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.046; color: "#C6CED8" }
                Text { anchors.baseline: parent.children[0].baseline
                    text: "км"; font.family: "Microgramma"
                    font.pixelSize: root.height * 0.020; color: "#48525F" }
            }
            Text { anchors.right: parent.right; text: "ОБЩИЙ"; font.family: "Microgramma"
                font.pixelSize: root.height * 0.016; font.letterSpacing: 0.8; color: "#46505F" }
        }

        // ── Шкала топлива (низ, во всю ширину) ──────────────────────────────
        Item {
            id: fuelBar
            readonly property var fe: root.edgesAt(0.945)
            x: fe.leftX + root._padX
            width: fe.rightX - fe.leftX - root._padX * 2
            y: root.height * 0.900
            height: root.height * 0.068

            Image {
                id: fuelIcon
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: root.height * 0.030; height: width
                source: "qrc:/assets/icons/fuel_low.png"
                fillMode: Image.PreserveAspectFit; smooth: true
                opacity: root.fuelLevel <= 20 ? 1.0 : 0.55
            }
            Text {
                id: fuelE; anchors { left: fuelIcon.right; leftMargin: root.height*0.012; verticalCenter: parent.verticalCenter }
                text: "E"; font.family: "Microgramma"; font.pixelSize: root.height * 0.017; color: "#5A6576"
            }

            // правый блок: проценты + литры
            Column {
                id: fuelRight
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 0
                Text {
                    anchors.right: parent.right
                    text: Math.round(root.fuelLevel) + "%"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.030; color: root.fuelColor
                    Behavior on color { ColorAnimation { duration: 500 } }
                }
                Text {
                    anchors.right: parent.right
                    text: "≈ " + Math.round(root.fuelNorm * root.tankCapacity) + " Л"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.015; color: "#46505F"
                }
            }
            Text {
                id: fuelF; anchors { right: fuelRight.left; rightMargin: root.height*0.014; verticalCenter: parent.verticalCenter }
                text: "F"; font.family: "Microgramma"; font.pixelSize: root.height * 0.017; color: "#6A7686"
            }

            // гладкий трек с градиентной заливкой
            Rectangle {
                id: fuelTrack
                anchors { left: fuelE.right; right: fuelF.left
                          leftMargin: root.height*0.014; rightMargin: root.height*0.014
                          verticalCenter: parent.verticalCenter }
                height: root.height * 0.020
                radius: height / 2
                color: "#090C12"
                border.width: 1; border.color: "#222A36"
                clip: true

                // заливка
                Rectangle {
                    id: fuelFill
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: Math.max(parent.height, parent.width * root.fuelNorm)
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.darker(root.fuelColor, 1.8) }
                        GradientStop { position: 1.0; color: root.fuelColor }
                    }
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

                    // верхний блик
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: parent.height * 0.48; radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#3DFFFFFF" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                    // яркая ведущая кромка
                    Rectangle {
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: 2; radius: 1
                        color: Qt.lighter(root.fuelColor, 1.6); opacity: 0.95
                    }
                }

                // деления 1/4 · 1/2 · 3/4
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        width: 1; height: fuelTrack.height * 0.5
                        color: "#3A4452"; opacity: 0.65
                        x: fuelTrack.width * (index + 1) / 4
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Критическое предупреждение
    // ════════════════════════════════════════════════════════════════════════
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.55; z: 5
        height: Math.min(critCol.contentHeight + root.height * 0.08, parent.height * 0.72)
        radius: 12; visible: root.hasCritical
        color: "#1C0706"; border.width: 1; border.color: "#882018"
        SequentialAnimation on opacity {
            running: root.hasCritical; loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.40; duration: 550; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.40; to: 1.0; duration: 550; easing.type: Easing.InOutQuad }
        }
        Image {
            anchors.top: parent.top; anchors.topMargin: root.height * 0.012
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.height * 0.034; height: width
            source: "qrc:/assets/icons/red_triangle.png"
            fillMode: Image.PreserveAspectFit; smooth: true; opacity: 0.8
        }
        ListView {
            id: critCol
            anchors { fill: parent; topMargin: root.height * 0.06; bottomMargin: root.height * 0.014
                      leftMargin: 4; rightMargin: 4 }
            clip: true; spacing: root.height * 0.005
            model: root.criticalLabels
            delegate: Text {
                required property string modelData
                width: critCol.width; text: modelData
                horizontalAlignment: Text.AlignHCenter
                font.family: "Microgramma"; font.pixelSize: root.height * 0.026
                font.letterSpacing: 1.5; color: "#FF7068"
            }
        }
    }
}
