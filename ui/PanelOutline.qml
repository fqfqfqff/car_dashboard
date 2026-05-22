// =============================================================================
// PanelOutline.qml — Замкнутый контур приборной панели
// =============================================================================

import QtQuick 2.15

Canvas {
    id: root
    anchors.fill: parent
    z: 999

    readonly property real gs:  parent.gaugeSize
    readonly property real gcx: gs / 2 + parent.width * 0.006
    readonly property real grx: parent.width - gs / 2 - parent.width * 0.006
    readonly property real gcy: parent.height / 2 - parent.height * 0.025

    readonly property color lineColor: "#B0B0C0"
    readonly property real  lineWidth: 1.5

    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()
    onGsChanged:     requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var W  = width
        var H  = height

        var semiR = gs * 0.50          // уменьшено: было 0.54

        var leftCX  = gcx
        var rightCX = grx
        var midCY   = gcy

        var topBulge = midCY - semiR - H * 0.12   // верхняя дуга выпуклая вверх
        var botBulge = midCY + semiR - H * 0.12   // нижняя дуга тоже выпуклая вверх (контрольная точка выше нижних концов)
        var midX     = W / 2

        ctx.beginPath()

        // Старт: верхняя точка левого полукруга (12 часов)
        ctx.moveTo(leftCX, midCY - semiR)

        // 1. Верхняя дуга — выпуклая вверх
        ctx.quadraticCurveTo(midX, topBulge, rightCX, midCY - semiR)

        // 2. Правый полукруг: 12 → 6 часов по правой стороне
        ctx.arc(rightCX, midCY, semiR, -Math.PI / 2, Math.PI / 2, false)

        // 3. Нижняя дуга — выпуклая вверх (контрольная точка выше обоих концов)
        ctx.quadraticCurveTo(midX, botBulge, leftCX, midCY + semiR)

        // 4. Левый полукруг: 6 → 12 часов по левой стороне
        ctx.arc(leftCX, midCY, semiR, Math.PI / 2, -Math.PI / 2, false)

        ctx.closePath()

        ctx.strokeStyle = root.lineColor
        ctx.lineWidth   = root.lineWidth
        ctx.lineJoin    = "round"
        ctx.lineCap     = "round"
        ctx.stroke()
    }
}
