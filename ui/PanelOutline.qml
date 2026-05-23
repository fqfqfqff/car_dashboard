import QtQuick 2.15

Canvas {
    id: root
    anchors.fill: parent
    z: 10

    readonly property real gs:  parent.gaugeSize
    readonly property real gcx: gs / 2 + parent.width * 0.004
    readonly property real grx: parent.width - gs / 2 - parent.width * 0.004
    readonly property real gcy: {
        var topH   = parent.height * 0.068
        var botH   = parent.height * 0.072 + parent.height * 0.132 + parent.height * 0.013
        return topH + (parent.height - topH - botH) / 2
    }

    readonly property real rpmNorm: parent.rpmNorm !== undefined ? parent.rpmNorm : 0.0

    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()
    onRpmNormChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var W      = width
        var H      = height
        var semiR  = gs * 0.505
        var leftCX = gcx
        var rightCX = grx
        var midCY  = gcy

        // Контрольные точки для плавных дуг
        var topBulge = midCY - semiR - H * 0.08
        var botBulge = midCY + semiR - H * 0.06
        var midX     = W / 2

        // ── Слой 1: широкая тень под рамкой ──────────────────────────────────
        ctx.save()
        ctx.beginPath()
        _tracePath(ctx, leftCX, rightCX, midCY, semiR, topBulge, botBulge, midX, 6)
        ctx.strokeStyle = "rgba(0,0,0,0.65)"
        ctx.lineWidth   = 12
        ctx.lineJoin    = "round"
        ctx.lineCap     = "round"
        ctx.stroke()
        ctx.restore()

        // ── Слой 2: тёмно-графитовый корпус (толстый) ────────────────────────
        ctx.save()
        ctx.beginPath()
        _tracePath(ctx, leftCX, rightCX, midCY, semiR, topBulge, botBulge, midX, 3)
        ctx.strokeStyle = "rgba(22,23,30,0.95)"
        ctx.lineWidth   = 8
        ctx.lineJoin    = "round"
        ctx.lineCap     = "round"
        ctx.stroke()
        ctx.restore()

        // ── Слой 3: хромовая линия (внешний блик) ────────────────────────────
        ctx.save()
        ctx.beginPath()
        _tracePath(ctx, leftCX, rightCX, midCY, semiR, topBulge, botBulge, midX, 1)
        var glowAlpha = 0.55 + rpmNorm * 0.25
        ctx.strokeStyle = "rgba(100,102,115," + glowAlpha + ")"
        ctx.lineWidth   = 1.8
        ctx.lineJoin    = "round"
        ctx.lineCap     = "round"
        ctx.stroke()
        ctx.restore()

        // ── Слой 4: внутренняя тёмная линия (граница рамка/циферблат) ─────────
        ctx.save()
        ctx.beginPath()
        _tracePath(ctx, leftCX, rightCX, midCY, semiR, topBulge, botBulge, midX, -3)
        ctx.strokeStyle = "rgba(4,4,8,0.90)"
        ctx.lineWidth   = 3.5
        ctx.lineJoin    = "round"
        ctx.lineCap     = "round"
        ctx.stroke()
        ctx.restore()

        // ── Слой 5: подсветка от приборов (красный ambient при работающем ДВС) ─
        if (rpmNorm > 0.05) {
            ctx.save()
            ctx.beginPath()
            _tracePath(ctx, leftCX, rightCX, midCY, semiR, topBulge, botBulge, midX, 0)
            ctx.strokeStyle = "rgba(255,59,48," + (rpmNorm * 0.18).toFixed(3) + ")"
            ctx.lineWidth   = 14
            ctx.lineJoin    = "round"
            ctx.lineCap     = "round"
            ctx.stroke()
            ctx.restore()
        }
    }

    // Вспомогательная функция трассировки контура (offset = смещение от базового контура)
    function _tracePath(ctx, leftCX, rightCX, midCY, semiR, topBulge, botBulge, midX, offset) {
        var r = semiR + offset
        if (r < 1) r = 1

        ctx.moveTo(leftCX, midCY - r)
        ctx.quadraticCurveTo(midX, topBulge - offset * 0.5, rightCX, midCY - r)
        ctx.arc(rightCX, midCY, r, -Math.PI / 2, Math.PI / 2, false)
        ctx.quadraticCurveTo(midX, botBulge - offset * 0.5, leftCX, midCY + r)
        ctx.arc(leftCX, midCY, r, Math.PI / 2, -Math.PI / 2, false)
        ctx.closePath()
    }
}
