// PanelOutline.qml — Audi cluster outline v9
// Точная геометрия + многослойная обводка + плавное RPM-свечение

import QtQuick 2.15

Canvas {
    id: root
    anchors.fill: parent
    z: 2

    readonly property real gs:   (parent && parent["gaugeSize"] !== undefined) ? parent["gaugeSize"] : 0
    readonly property real gCY:  (parent && parent["gaugeCY"]   !== undefined) ? parent["gaugeCY"]   : height * 0.44
    readonly property real gmH:  (parent && parent["gaugeMarH"] !== undefined) ? parent["gaugeMarH"] : width  * 0.010
    readonly property real rpmN: (parent && parent["_smoothRpmNorm"] !== undefined) ? parent["_smoothRpmNorm"] : 0.0

    readonly property real r:    gs * 0.5
    readonly property real lCX:  gmH + r
    readonly property real rCX:  width - gmH - r
    readonly property real midX: width / 2

    // Контрольные точки Безье — горизонтальная касательная точно на краю дуги
    readonly property real topCtrlY: gCY - r - gs * 0.030
    readonly property real botCtrlY: gCY + r + gs * 0.010

    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()
    onGsChanged:     requestPaint()
    onGCYChanged:    requestPaint()
    onRpmNChanged:   requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (gs < 10) return

        // ── 1. Объёмная радиальная заливка внутри контура ────────────────────
        var radFill = ctx.createRadialGradient(midX, gCY, 0, midX, gCY, r * 1.55)
        radFill.addColorStop(0.00, "rgba(22,26,36,0.00)")
        radFill.addColorStop(0.50, "rgba(8,10,14,0.07)")
        radFill.addColorStop(0.85, "rgba(0,0,0,0.18)")
        radFill.addColorStop(1.00, "rgba(0,0,0,0.32)")
        ctx.save()
        ctx.beginPath(); _path(ctx, r - 8)
        ctx.fillStyle = radFill; ctx.fill()
        ctx.restore()

        // ── 2. Внешняя рассеянная тень — 5 слоёв ────────────────────────────
        var shadows = [
            { dr: 20, lw: 44, a: 0.08 },
            { dr: 14, lw: 36, a: 0.11 },
            { dr:  8, lw: 28, a: 0.13 },
            { dr:  4, lw: 20, a: 0.12 },
            { dr:  1, lw: 14, a: 0.08 }
        ]
        for (var i = 0; i < shadows.length; i++) {
            var s = shadows[i]
            ctx.beginPath(); _path(ctx, r + s.dr)
            ctx.strokeStyle = "rgba(0,0,0," + s.a + ")"
            ctx.lineWidth = s.lw; ctx.lineJoin = "round"; ctx.stroke()
        }

        // ── 3. Тёмная основная рамка (база под хром) ─────────────────────────
        ctx.beginPath(); _path(ctx, r + 5)
        ctx.strokeStyle = "rgba(12,14,18,1.0)"
        ctx.lineWidth = 12; ctx.lineJoin = "round"; ctx.stroke()

        // ── 4. Внешний тёмный хром — матовый ────────────────────────────────
        ctx.beginPath(); _path(ctx, r + 2)
        ctx.strokeStyle = "rgba(28,33,42,1.0)"
        ctx.lineWidth = 5; ctx.lineJoin = "round"; ctx.stroke()

        // ── 5. Metallic highlight — яркая грань ──────────────────────────────
        // Линейный градиент имитирует отражение света сверху
        var hlGrad = ctx.createLinearGradient(lCX, gCY - r, rCX, gCY + r)
        hlGrad.addColorStop(0.00, "rgba(110,125,145,0.95)")
        hlGrad.addColorStop(0.25, "rgba(90,102,118,0.85)")
        hlGrad.addColorStop(0.50, "rgba(60,70,85,0.75)")
        hlGrad.addColorStop(0.75, "rgba(42,50,62,0.65)")
        hlGrad.addColorStop(1.00, "rgba(70,82,98,0.80)")
        ctx.beginPath(); _path(ctx, r + 0.5)
        ctx.strokeStyle = hlGrad
        ctx.lineWidth = 2.0; ctx.lineJoin = "round"; ctx.stroke()

        // ── 6. RPM-свечение — 4 слоя (ПОВЕРХ хрома) ─────────────────────────
        if (rpmN > 0.005) {
            var rc = "255,59,48"
            // Широкий атмосферный ореол
            ctx.beginPath(); _path(ctx, r + 1)
            ctx.strokeStyle = "rgba(" + rc + "," + (rpmN * 0.12).toFixed(3) + ")"
            ctx.lineWidth = 28; ctx.lineJoin = "round"; ctx.stroke()
            // Средний ореол
            ctx.beginPath(); _path(ctx, r + 1)
            ctx.strokeStyle = "rgba(" + rc + "," + (rpmN * 0.22).toFixed(3) + ")"
            ctx.lineWidth = 14; ctx.lineJoin = "round"; ctx.stroke()
            // Острый край
            ctx.beginPath(); _path(ctx, r + 1)
            ctx.strokeStyle = "rgba(" + rc + "," + (rpmN * 0.45).toFixed(3) + ")"
            ctx.lineWidth = 5; ctx.lineJoin = "round"; ctx.stroke()
            // Лазерный контур
            ctx.beginPath(); _path(ctx, r + 1)
            ctx.strokeStyle = "rgba(" + rc + "," + (rpmN * 0.80).toFixed(3) + ")"
            ctx.lineWidth = 1.5; ctx.lineJoin = "round"; ctx.stroke()
        }

        // ── 7. Внутренний shadow — глубина фаски ─────────────────────────────
        ctx.beginPath(); _path(ctx, r - 2)
        ctx.strokeStyle = "rgba(4,5,8,0.95)"
        ctx.lineWidth = 4; ctx.lineJoin = "round"; ctx.stroke()

        // ── 8. Внутренний highlight — тонкая фаска ───────────────────────────
        ctx.beginPath(); _path(ctx, r - 5)
        ctx.strokeStyle = "rgba(40,50,64,0.55)"
        ctx.lineWidth = 1.2; ctx.lineJoin = "round"; ctx.stroke()

        // ── 9. Глянцевый блик сверху — имитация стекла над кластером ─────────
        var glassGrad = ctx.createLinearGradient(lCX, gCY - r, lCX, gCY - r * 0.5)
        glassGrad.addColorStop(0.0, "rgba(255,255,255,0.025)")
        glassGrad.addColorStop(1.0, "rgba(255,255,255,0.000)")
        ctx.save()
        ctx.beginPath(); _path(ctx, r - 8)
        ctx.clip()
        ctx.fillStyle = glassGrad
        ctx.fillRect(0, gCY - r, width, r * 0.55)
        ctx.restore()
    }

    function _path(ctx, radius) {
        var topY = topCtrlY - (r - radius)
        var botY = botCtrlY + (r - radius)
        ctx.moveTo(lCX, gCY - radius)
        ctx.quadraticCurveTo(midX, topY, rCX, gCY - radius)
        ctx.arc(rCX, gCY, radius, -Math.PI / 2,  Math.PI / 2, false)
        ctx.quadraticCurveTo(midX, botY, lCX, gCY + radius)
        ctx.arc(lCX, gCY, radius,  Math.PI / 2, -Math.PI / 2, false)
        ctx.closePath()
    }
}
