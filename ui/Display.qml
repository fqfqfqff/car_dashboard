import QtQuick 2.15

Item {
    id: root
    // clip отключён, чтобы Canvas мог рисовать дуги вплотную к гаджам
    clip: false

    readonly property var dm:  (typeof dataModel !== "undefined" && dataModel !== null) ? dataModel : null
    readonly property var sim: (typeof simulator  !== "undefined" && simulator  !== null) ? simulator : null

    property var  criticalLabels: []
    property bool hasCritical:    false
    property real gaugeR: 0
    property real arcR:   0   // радиус видимого диска гаджа (≈ 0.95·gaugeR), задаётся снаружи

    // Координаты центров гаджей в локальной системе Display
    property real speedCXLocal: 0
    property real rpmCXLocal:   0
    property real gaugeCYLocal: 0

    readonly property real tankCapacity: 50.0

    readonly property real fuelNorm: root.dm ? Math.max(0, Math.min(1, root.dm.fuelLevel / 100.0)) : 0.75
    readonly property color fuelColor: {
        var f = root.dm ? root.dm.fuelLevel : 75
        if (f <= 10) return "#FF3B30"
        if (f <= 25) return "#FFB300"
        return "#0A84FF"
    }

    readonly property color tempColor: {
        var t = root.dm ? root.dm.engineTemp : 20
        if (t >= 110) return "#FF3B30"
        if (t >= 90)  return "#FFCC00"
        if (t >= 60)  return "#30D158"
        return "#4A8FD4"
    }

    readonly property real rangeKm: {
        var fuel = root.dm ? root.dm.fuelLevel : 0
        var avg  = root.sim ? root.sim.fuelAvg : 0
        if (avg < 0.1 || fuel <= 0) return 0
        return (fuel / 100.0 * root.tankCapacity) / (avg / 100.0)
    }

    // Края вогнутой фигуры на уровне y (локальные координаты)
    function shapeEdgesAtY(localY) {
        var cy = root.gaugeCYLocal
        var R  = root.arcR
        var d  = localY - cy
        var h  = Math.sqrt(Math.max(0, R * R - d * d))
        return { leftX:  root.speedCXLocal + h,
                 rightX: root.rpmCXLocal   - h }
    }

    // ── Фон: чисто чёрная вогнутая фигура ──────────────────────────────────────
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        z: 0

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var lCX = root.speedCXLocal
            var rCX = root.rpmCXLocal
            var cy  = root.gaugeCYLocal
            var R   = root.arcR
            if (R < 10) return

            var topD = cy
            var botD = height - cy

            var rTopAngle = Math.atan2(-topD, -(Math.sqrt(Math.max(0, R*R - topD*topD))))
            var rBotAngle = Math.atan2( botD, -(Math.sqrt(Math.max(0, R*R - botD*botD))))
            var lBotAngle = Math.atan2( botD,  (Math.sqrt(Math.max(0, R*R - botD*botD))))
            var lTopAngle = Math.atan2(-topD,  (Math.sqrt(Math.max(0, R*R - topD*topD))))

            var topLeftX  = lCX + Math.sqrt(Math.max(0, R*R - topD*topD))
            var topRightX = rCX - Math.sqrt(Math.max(0, R*R - topD*topD))
            var botLeftX  = lCX + Math.sqrt(Math.max(0, R*R - botD*botD))

            ctx.beginPath()
            ctx.moveTo(topLeftX, 0)
            ctx.lineTo(topRightX, 0)
            ctx.arc(rCX, cy, R, rTopAngle, rBotAngle, true)
            ctx.lineTo(botLeftX, height)
            ctx.arc(lCX, cy, R, lBotAngle, lTopAngle, true)
            ctx.closePath()

            // Чисто чёрный фон, совпадает с фоном кластера
            ctx.fillStyle = "#07080D"
            ctx.fill()
        }

        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()
    }
    onArcRChanged:        bgCanvas.requestPaint()
    onSpeedCXLocalChanged: bgCanvas.requestPaint()
    onRpmCXLocalChanged:   bgCanvas.requestPaint()
    onGaugeCYLocalChanged: bgCanvas.requestPaint()

    // ── Контент ──────────────────────────────────────────────────────────────────
    Item {
        id: content
        property real narrowLeftX:  root.shapeEdgesAtY(root.gaugeCYLocal).leftX
        property real narrowRightX: root.shapeEdgesAtY(root.gaugeCYLocal).rightX
        property real safeMargin:   root.width * 0.02

        x:      narrowLeftX + safeMargin
        y:      root.height * 0.03
        width:  narrowRightX - narrowLeftX - safeMargin * 2
        height: root.height - root.height * 0.06
        clip: true
        z: 1
        opacity: root.hasCritical ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        // ═══ Шапка: время слева, иконки по центру, дата справа ═══
        Item {
            id: header
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: root.height * 0.12

            Column {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 1
                Text {
                    id: clockTxt
                    text: Qt.formatTime(new Date(), "HH:mm")
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.052
                    color: "#CBD2DC"
                    Timer {
                        interval: 1000; running: true; repeat: true
                        onTriggered: clockTxt.text = Qt.formatTime(new Date(), "HH:mm")
                    }
                }
                Text {
                    text: Qt.formatDate(new Date(), "ddd").toUpperCase()
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                    color: "#485060"; font.letterSpacing: 2.0
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: parent.width * 0.04

                Image {
                    width: root.height * 0.032; height: width
                    source: "qrc:/assets/icons/low_beam.png"
                    fillMode: Image.PreserveAspectFit; smooth: true
                    visible: root.dm ? root.dm.lowBeam : false
                }
                Image {
                    width: root.height * 0.032; height: width
                    source: "qrc:/assets/icons/high_beam.png"
                    fillMode: Image.PreserveAspectFit; smooth: true
                    visible: root.dm ? root.dm.highBeam : false
                }
                Image {
                    width: root.height * 0.032; height: width
                    source: "qrc:/assets/icons/fog.png"
                    fillMode: Image.PreserveAspectFit; smooth: true
                    visible: root.dm ? root.dm.fogLights : false
                }

                Rectangle {
                    width: root.height * 0.16; height: root.height * 0.036
                    radius: height / 2
                    visible: root.dm ? root.dm.cruiseActive : false
                    color: "#0D1A12"; border.width: 1; border.color: "#224433"
                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            text: "КРУИЗ"
                            font.family: "Microgramma"; font.pixelSize: root.height * 0.013
                            color: "#6DC88A"; font.letterSpacing: 1.0
                        }
                        Text {
                            text: (root.sim && root.sim.cruiseTarget > 0)
                                  ? Math.round(root.sim.cruiseTarget) : "—"
                            font.family: "Microgramma"; font.pixelSize: root.height * 0.013
                            color: "#A8E8BC"
                        }
                    }
                }
            }

            Column {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 1
                Text {
                    id: dateTxt
                    anchors.right: parent.right
                    text: Qt.formatDate(new Date(), "dd.MM")
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.052
                    color: "#CBD2DC"
                    Timer {
                        interval: 60000; running: true; repeat: true
                        onTriggered: dateTxt.text = Qt.formatDate(new Date(), "dd.MM")
                    }
                }
                Text {
                    anchors.right: parent.right
                    text: Qt.formatDate(new Date(), "yyyy")
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                    color: "#485060"; font.letterSpacing: 1.5
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right
                          leftMargin: parent.width * 0.04; rightMargin: parent.width * 0.04 }
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: "#1A2030" }
                    GradientStop { position: 0.7; color: "#1A2030" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        // ═══ Основная зона: УДЕРЖАНИЕ В ПОЛОСЕ (LKAS) ═══
        Item {
            id: laneZone
            anchors { left: parent.left; right: parent.right
                      top: header.bottom; bottom: sep2.top }

            // Активна ли система: включена И двигатель работает
            readonly property bool lkActive: root.dm ? (root.dm.laneAssist && root.dm.engineRunning) : false

            // Заголовок системы + статус
            Row {
                id: laneTitle
                anchors { top: parent.top; topMargin: root.height * 0.010
                          horizontalCenter: parent.horizontalCenter }
                spacing: root.height * 0.014
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "УДЕРЖАНИЕ В ПОЛОСЕ"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.020
                    font.letterSpacing: 2.5
                    color: laneZone.lkActive ? "#C9543F" : "#46505F"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: stBadge.width + root.height * 0.022; height: root.height * 0.026
                    radius: height / 2
                    color: laneZone.lkActive ? "#1A0604" : "#0C0E12"
                    border.width: 1
                    border.color: laneZone.lkActive ? "#7A271C" : "#222833"
                    Behavior on color { ColorAnimation { duration: 300 } }
                    // мягкое пульсирование индикатора при активной системе
                    Rectangle {
                        anchors { left: parent.left; leftMargin: root.height*0.010
                                  verticalCenter: parent.verticalCenter }
                        width: root.height*0.009; height: width; radius: width/2
                        visible: laneZone.lkActive
                        color: "#FF3B30"
                        SequentialAnimation on opacity {
                            running: laneZone.lkActive; loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.25; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        id: stBadge
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: laneZone.lkActive ? root.height*0.006 : 0
                        text: laneZone.lkActive ? "АКТИВНО" : "ВЫКЛ"
                        font.family: "Microgramma"; font.pixelSize: root.height * 0.0115
                        font.letterSpacing: 1.0
                        color: laneZone.lkActive ? "#FF6A5C" : "#46505F"
                    }
                }
            }

            // Запас хода — компактно, в правом верхнем углу зоны
            Column {
                anchors { right: parent.right; top: parent.top; topMargin: root.height * 0.004 }
                spacing: 0
                Text {
                    anchors.right: parent.right
                    text: "ЗАПАС ХОДА"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.014
                    font.letterSpacing: 1.2; color: "#3E4858"
                }
                Text {
                    anchors.right: parent.right
                    text: {
                        if (!(root.dm && root.dm.engineRunning)) return "—"
                        var r = root.rangeKm
                        return r > 0 ? "~" + Math.round(r) + " км" : "—"
                    }
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.026
                    color: {
                        var r = root.rangeKm
                        if (!(root.dm && root.dm.engineRunning) || r <= 0) return "#3E4858"
                        if (r <= 50) return "#FF3B30"
                        if (r <= 100) return "#FFB300"
                        return "#AEB8C6"
                    }
                }
            }

            // Перспективная дорога + полоса + треугольник-«машина»
            Canvas {
                id: laneCanvas
                anchors { left: parent.left; right: parent.right
                          top: laneTitle.bottom; bottom: parent.bottom
                          topMargin: root.height * 0.008
                          leftMargin: root.width * 0.04; rightMargin: root.width * 0.04 }

                property real phase:  0.0                  // фаза «движения» разметки
                property bool active: laneZone.lkActive
                onActiveChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var w = width, h = height
                    if (w < 20 || h < 20) return

                    // Цвета: активна — красный, выключена — приглушённый серый
                    var cMain = active ? "255,59,48"   : "92,102,116"
                    var cHot  = active ? "255,150,130" : "150,160,172"
                    var dim   = active ? 1.0 : 0.55

                    var vpX = w * 0.5,  vpY = h * 0.05          // точка схода
                    var blX = w * 0.06, brX = w * 0.94          // низ полосы (шире)
                    var byY = h * 0.99
                    var tlX = vpX - w * 0.040                   // верх (узкий зазор у схода)
                    var trX = vpX + w * 0.040
                    var tY  = vpY

                    // 1) Заливка эго-полосы — градиент, гаснет вверх
                    var grad = ctx.createLinearGradient(0, byY, 0, tY)
                    grad.addColorStop(0.0,  "rgba(" + cMain + "," + (0.16*dim).toFixed(3) + ")")
                    grad.addColorStop(0.55, "rgba(" + cMain + "," + (0.05*dim).toFixed(3) + ")")
                    grad.addColorStop(1.0,  "rgba(" + cMain + ",0.0)")
                    ctx.beginPath()
                    ctx.moveTo(blX, byY); ctx.lineTo(tlX, tY)
                    ctx.lineTo(trX, tY);  ctx.lineTo(brX, byY); ctx.closePath()
                    ctx.fillStyle = grad; ctx.fill()

                    // 2) Поперечные перспективные «рейки» — бегут на зрителя (только активно)
                    var ph = active ? phase : 0
                    var rungs = 7
                    for (var i = 0; i < rungs; i++) {
                        var p = ((i + ph) % rungs) / rungs
                        var t = Math.pow(p, 2.3)                // плотнее у схода
                        var ry = tY + (byY - tY) * t
                        var lx = tlX + (blX - tlX) * t
                        var rx = trX + (brX - trX) * t
                        var a  = (0.03 + 0.16 * t) * dim
                        ctx.strokeStyle = "rgba(" + cHot + "," + a.toFixed(3) + ")"
                        ctx.lineWidth = 0.8 + 1.4 * t
                        ctx.beginPath(); ctx.moveTo(lx, ry); ctx.lineTo(rx, ry); ctx.stroke()
                    }

                    // 3) Границы полосы — светящиеся линии (многослойный glow)
                    function laneLine(x0, y0, x1, y1) {
                        var passes = [ [11, 0.05], [6, 0.11], [2.6, 0.50], [1.2, 0.95] ]
                        ctx.lineCap = "round"
                        for (var k = 0; k < passes.length; k++) {
                            ctx.strokeStyle = "rgba(" + cMain + "," + (passes[k][1]*dim).toFixed(3) + ")"
                            ctx.lineWidth = passes[k][0]
                            ctx.beginPath(); ctx.moveTo(x0, y0); ctx.lineTo(x1, y1); ctx.stroke()
                        }
                    }
                    laneLine(blX, byY, tlX, tY)
                    laneLine(brX, byY, trX, tY)

                    // 4) Треугольник-«машина» (как курсор навигации) у низа полосы
                    var cx = w * 0.5
                    var apexY = h * 0.46
                    var baseY = h * 0.86
                    var hw    = w * 0.058
                    var notch = (baseY - apexY) * 0.30
                    function triPath() {
                        ctx.beginPath()
                        ctx.moveTo(cx, apexY)
                        ctx.lineTo(cx + hw, baseY)
                        ctx.lineTo(cx, baseY - notch)
                        ctx.lineTo(cx - hw, baseY)
                        ctx.closePath()
                    }
                    // Свечение вокруг (расширяющиеся обводки)
                    ctx.lineJoin = "round"
                    var gp = [ [13, 0.06], [8, 0.12], [4, 0.22] ]
                    for (var gi = 0; gi < gp.length; gi++) {
                        triPath()
                        ctx.strokeStyle = "rgba(" + cMain + "," + (gp[gi][1]*dim).toFixed(3) + ")"
                        ctx.lineWidth = gp[gi][0]; ctx.stroke()
                    }
                    // Основная заливка с градиентом
                    var tg = ctx.createLinearGradient(cx, apexY, cx, baseY)
                    tg.addColorStop(0.0, "rgba(" + cHot  + "," + (0.98*dim).toFixed(3) + ")")
                    tg.addColorStop(1.0, "rgba(" + cMain + "," + (0.72*dim).toFixed(3) + ")")
                    triPath(); ctx.fillStyle = tg; ctx.fill()
                    // Контур
                    triPath()
                    ctx.strokeStyle = "rgba(" + cHot + "," + (0.95*dim).toFixed(3) + ")"
                    ctx.lineWidth = 1.4; ctx.stroke()
                }

                onWidthChanged:  requestPaint()
                onHeightChanged: requestPaint()
                onPhaseChanged:  requestPaint()

                // Анимация бегущей разметки — только когда система активна
                Timer {
                    interval: 70; repeat: true
                    running: laneZone.lkActive
                    onTriggered: laneCanvas.phase = (laneCanvas.phase + 0.12) % 7
                }
            }
        }

        // ═══ Разделитель ═══
        Rectangle {
            id: sep2
            anchors { bottom: dataZone.top; left: parent.left; right: parent.right
                      leftMargin: parent.width * 0.03; rightMargin: parent.width * 0.03 }
            height: 1; color: "#1A2030"
        }

        // ═══ Зона данных ═══
        Item {
            id: dataZone
            anchors { left: parent.left; right: parent.right; bottom: fuelBar.top }
            anchors.bottomMargin: root.height * 0.008
            height: root.height * 0.210

            Column {
                anchors.fill: parent
                spacing: root.height * 0.008

                // Строка 1: Пробег | Расход
                Row {
                    width: parent.width; height: root.height * 0.072

                    Item {
                        width: parent.width * 0.5; height: parent.height
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Text {
                                text: "ПРОБЕГ"
                                font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                                font.letterSpacing: 1.5; color: "#3E4858"
                            }
                            Text {
                                text: {
                                    var km = Math.round(root.dm ? root.dm.odometer : 0)
                                    return km.toLocaleString(Qt.locale("ru_RU"), "f", 0) + " км"
                                }
                                font.family: "Microgramma"; font.pixelSize: root.height * 0.042
                                color: "#C2CAD4"
                            }
                        }
                    }

                    Item {
                        width: parent.width * 0.5; height: parent.height
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right; spacing: 2
                            Text {
                                anchors.right: parent.right; text: "РАСХОД"
                                font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                                font.letterSpacing: 1.5; color: "#3E4858"
                            }
                            Text {
                                anchors.right: parent.right
                                text: {
                                    if (!(root.dm && root.dm.engineRunning)) return "—.— л/100"
                                    var f = root.sim ? root.sim.fuelL100 : -1
                                    return f >= 0 ? f.toFixed(1) + " л/100" : "—.— л/100"
                                }
                                font.family: "Microgramma"; font.pixelSize: root.height * 0.042
                                color: {
                                    if (!(root.dm && root.dm.engineRunning)) return "#2E3848"
                                    var f = root.sim ? root.sim.fuelL100 : -1
                                    if (f < 0) return "#2E3848"
                                    return f > 20 ? "#FF3B30" : f > 12 ? "#FFCC00" : "#C2CAD4"
                                }
                                Behavior on color { ColorAnimation { duration: 500 } }
                            }
                        }
                    }
                }

                // Строка 2: Температура ДВС | Средний расход
                Row {
                    width: parent.width; height: root.height * 0.072

                    Item {
                        width: parent.width * 0.5; height: parent.height
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Text {
                                text: "ТЕМП. ДВС"
                                font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                                font.letterSpacing: 1.5; color: "#3E4858"
                            }
                            Text {
                                text: Math.round(root.dm ? root.dm.engineTemp : 0) + "°C"
                                font.family: "Microgramma"; font.pixelSize: root.height * 0.042
                                color: root.tempColor
                                Behavior on color { ColorAnimation { duration: 500 } }
                            }
                        }
                    }

                    Item {
                        width: parent.width * 0.5; height: parent.height
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right; spacing: 2
                            Text {
                                anchors.right: parent.right; text: "СРЕДНИЙ"
                                font.family: "Microgramma"; font.pixelSize: root.height * 0.018
                                font.letterSpacing: 1.5; color: "#3E4858"
                            }
                            Text {
                                anchors.right: parent.right
                                text: {
                                    if (!(root.dm && root.dm.engineRunning)) return "—.— л/100"
                                    var f = root.sim ? root.sim.fuelAvg : 0
                                    return f > 0 ? f.toFixed(1) + " л/100" : "0.0 л/100"
                                }
                                font.family: "Microgramma"; font.pixelSize: root.height * 0.042
                                color: {
                                    if (!(root.dm && root.dm.engineRunning)) return "#2E3848"
                                    var f = root.sim ? root.sim.fuelAvg : 0
                                    return f > 15 ? "#FF3B30" : f > 10 ? "#FFCC00" : "#C2CAD4"
                                }
                                Behavior on color { ColorAnimation { duration: 500 } }
                            }
                        }
                    }
                }
            }
        }

        // ═══ Полоса топлива ═══
        Item {
            id: fuelBar
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors.bottomMargin: root.height * 0.005
            height: root.height * 0.055

            Row {
                anchors.fill: parent
                spacing: root.height * 0.008

                Image {
                    width: root.height * 0.024; height: width
                    source: "qrc:/assets/icons/fuel_low.png"
                    fillMode: Image.PreserveAspectFit; smooth: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - root.height * 0.024 - fuelPct.width - root.height * 0.024
                    height: root.height * 0.020

                    Rectangle {
                        anchors.fill: parent; radius: height / 2
                        color: "#080A0E"; border.width: 1; border.color: "#1A2030"
                    }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 2 }
                        width: Math.max(height - 4, (parent.width - 4) * root.fuelNorm)
                        radius: (parent.height - 4) / 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.darker(root.fuelColor, 1.6) }
                            GradientStop { position: 1.0; color: root.fuelColor }
                        }
                        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    id: fuelPct
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.dm ? root.dm.fuelLevel : 0) + "%"
                    font.family: "Microgramma"; font.pixelSize: root.height * 0.024
                    color: root.fuelColor
                    Behavior on color { ColorAnimation { duration: 500 } }
                }
            }
        }
    }

    // ═══ Критическое предупреждение ═══
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.55; z: 5
        height: Math.min(critCol.contentHeight + root.height * 0.08, parent.height * 0.72)
        radius: 12
        visible: root.hasCritical
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
