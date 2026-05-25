// PanelOutline.qml — контур кластера. v7.
// Читает gaugeSize / gaugeCY / gaugeMarH из родителя (Dashboard).
// Все координаты выведены из единой системы — нет рассинхрона с гаджами.

import QtQuick 2.15

Canvas {
    id: root
    anchors.fill: parent
    z: 10

    // Читаем из Dashboard
    readonly property real gs:    (parent && parent["gaugeSize"]  !== undefined) ? parent["gaugeSize"]  : 0
    readonly property real gCY:   (parent && parent["gaugeCY"]    !== undefined) ? parent["gaugeCY"]    : height * 0.44
    readonly property real gmH:   (parent && parent["gaugeMarH"]  !== undefined) ? parent["gaugeMarH"]  : width  * 0.010
    readonly property real rpmN:  (parent && parent["rpmNorm"]    !== undefined) ? parent["rpmNorm"]    : 0.0

    // Центры гаджей
    readonly property real lCX: gmH + gs / 2
    readonly property real rCX: width - gmH - gs / 2

    onWidthChanged:   requestPaint()
    onHeightChanged:  requestPaint()
    onGsChanged:      requestPaint()
    onGCYChanged:     requestPaint()
    onRpmNChanged:    requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (gs < 10) return

        const r        = gs * 0.505
        const midX     = width / 2
        // Контрольные точки кривых Безье: соединяем верхние/нижние точки дуг
        const topCtrlY = gCY - r - height * 0.042
        const botCtrlY = gCY + r - height * 0.010

        // Тень снаружи
        traceOutline(ctx, r + 18, topCtrlY, botCtrlY, midX, "rgba(0,0,0,0.55)",     24)
        // Основная тёмная рамка
        traceOutline(ctx, r + 6,  topCtrlY, botCtrlY, midX, "rgba(18,21,27,0.98)",  11)
        // Светлый edge (металл)
        traceOutline(ctx, r + 1,  topCtrlY, botCtrlY, midX, "rgba(72,80,92,0.88)",  1.8)
        // Внутренняя тень
        traceOutline(ctx, r - 4,  topCtrlY, botCtrlY, midX, "rgba(6,7,10,0.97)",    3.5)

        // Подсветка от оборотов
        if (rpmN > 0.02) {
            traceOutline(
                ctx, r, topCtrlY, botCtrlY, midX,
                "rgba(255,59,48," + (0.06 + rpmN * 0.22).toFixed(3) + ")",
                14
            )
        }

        // Лёгкая атмосферная заливка внутри
        const fill = ctx.createLinearGradient(0, gCY - r, 0, gCY + r)
        fill.addColorStop(0.0,  "rgba(32,36,44,0.16)")
        fill.addColorStop(0.45, "rgba(10,12,16,0.04)")
        fill.addColorStop(1.0,  "rgba(255,59,48," + (rpmN * 0.05).toFixed(3) + ")")
        ctx.save()
        ctx.beginPath()
        clusterPath(ctx, r - 7, topCtrlY, botCtrlY, midX)
        ctx.fillStyle = fill
        ctx.fill()
        ctx.restore()
    }

    function traceOutline(ctx, radius, topCtrlY, botCtrlY, midX, strokeStyle, lineWidth) {
        ctx.save()
        ctx.beginPath()
        clusterPath(ctx, radius, topCtrlY, botCtrlY, midX)
        ctx.strokeStyle = strokeStyle
        ctx.lineWidth   = lineWidth
        ctx.lineJoin    = "round"
        ctx.lineCap     = "round"
        ctx.stroke()
        ctx.restore()
    }

    function clusterPath(ctx, radius, topCtrlY, botCtrlY, midX) {
        ctx.moveTo(lCX, gCY - radius)
        ctx.quadraticCurveTo(midX, topCtrlY, rCX, gCY - radius)
        ctx.arc(rCX, gCY, radius, -Math.PI / 2,  Math.PI / 2, false)
        ctx.quadraticCurveTo(midX, botCtrlY, lCX, gCY + radius)
        ctx.arc(lCX, gCY, radius,  Math.PI / 2, -Math.PI / 2, false)
        ctx.closePath()
    }
}
