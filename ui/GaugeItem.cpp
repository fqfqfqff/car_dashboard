#include "GaugeItem.h"

#include <QtMath>
#include <QPainterPath>
#include <QRadialGradient>
#include <QConicalGradient>
#include <QLinearGradient>
#include <QFontMetricsF>

// =============================================================================
// Цветовая система — зеркало DesignSystem.qml
// =============================================================================
namespace DS {
static const QColor BG_DEEP      {   4,   4,   6 };
static const QColor BG_PRIMARY   {  10,  10,  14 };
static const QColor BG_SECONDARY {  18,  18,  24 };
static const QColor BG_SURFACE   {  28,  28,  36 };
static const QColor TEXT_PRIMARY { 240, 240, 245, 230 };
static const QColor TEXT_SEC     { 170, 170, 180 };
static const QColor TEXT_DIM     {  90,  90, 100 };
static const QColor CRITICAL     { 255,  59,  48 };
static const QColor CRITICAL_DIM { 255,  59,  48, 80 };
static const QColor WARNING      { 255, 204,   0 };
static const QColor INFO_GREEN   {  48, 209,  88 };
static const QColor INFO_BLUE    {  10, 132, 255 };
static const QColor ARC_PASSIVE  {  55,  55,  65, 180 };
static const QColor CHROME_HI    { 110, 112, 120, 200 };
static const QColor CHROME_MID   {  60,  62,  70, 180 };
static const QColor CHROME_LO    {  30,  32,  38, 220 };
static const QColor DIVIDER      {  40,  40,  50 };
static const QColor NEEDLE_COLOR { 245, 245, 250, 245 };
}

// =============================================================================
GaugeItem::GaugeItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setRenderTarget(QQuickPaintedItem::FramebufferObject);
    setAntialiasing(true);
    setOpaquePainting(false);
}

void GaugeItem::setValue(double v)
{
    v = qBound(m_minValue, v, m_maxValue);
    if (qFuzzyCompare(m_value, v)) return;
    m_value = v;
    emit valueChanged();
    update();
}

double GaugeItem::normalize(double v) const
{
    const bool isTacho = (m_maxValue > 999.0);
    if (isTacho)
        return (v - m_minValue) / (m_maxValue - m_minValue);
    const double center = 100.0;
    if (v <= center)
        return 0.5 * (v - m_minValue) / (center - m_minValue);
    return 0.5 + 0.5 * (v - center) / (m_maxValue - center);
}

// =============================================================================
void GaugeItem::paint(QPainter *painter)
{
    painter->setRenderHint(QPainter::Antialiasing,          true);
    painter->setRenderHint(QPainter::TextAntialiasing,      true);
    painter->setRenderHint(QPainter::SmoothPixmapTransform, true);

    const double side   = qMin(width(), height());
    const QPointF center(width() / 2.0, height() / 2.0);

    const double outerR = side * 0.490;   // край пластиковой рамки
    const double faceR  = side * 0.455;   // край циферблата (внутри рамки)
    const double innerR = side * 0.270;   // граница центрального дисплея

    const double norm = qBound(0.0, normalize(m_value), 1.0);

    drawBackground      (painter, center, faceR, innerR);
    drawOuterRing       (painter, center, outerR);
    drawDangerZoneFill  (painter, center, faceR, norm);
    drawArcTrack        (painter, center, faceR, norm);
    drawTicks           (painter, center, faceR, innerR);
    drawTickLabels      (painter, center, faceR, innerR);
    drawInnerArc        (painter, center, innerR);
    drawGlowRing        (painter, center, innerR);
    drawNeedle          (painter, center, faceR, innerR, norm);
    drawCenterHub       (painter, center);
    drawCenterText      (painter, center, innerR, norm);
    drawInnerIndicators (painter, center, innerR);
}

// =============================================================================
// Фон: глубокий тёмный, радиальный градиент с текстурой глубины
// =============================================================================
void GaugeItem::drawBackground(QPainter *p, QPointF c, double faceR, double /*innerR*/)
{
    // Основной фон циферблата
    QRadialGradient bg(c, faceR);
    bg.setColorAt(0.00, DS::BG_SURFACE);
    bg.setColorAt(0.45, DS::BG_SECONDARY);
    bg.setColorAt(0.75, DS::BG_PRIMARY);
    bg.setColorAt(1.00, DS::BG_DEEP);

    p->setPen(Qt::NoPen);
    p->setBrush(bg);
    p->drawEllipse(c, faceR, faceR);

    // Тонкая граница между фоном и рамкой
    p->setPen(QPen(QColor(8, 8, 12), 1.5));
    p->setBrush(Qt::NoBrush);
    p->drawEllipse(c, faceR, faceR);
}

// =============================================================================
// Внешняя рамка: многослойная пластиково-хромовая окантовка
// =============================================================================
void GaugeItem::drawOuterRing(QPainter *p, QPointF c, double outerR)
{
    const double faceR = outerR * (0.455 / 0.490);

    // Слой 1: тёмный пластиковый корпус (широкий)
    QRadialGradient plasticGrad(c, outerR);
    plasticGrad.setFocalPoint(QPointF(c.x() - outerR * 0.15, c.y() - outerR * 0.15));
    plasticGrad.setColorAt(0.00, QColor(45, 46, 54));
    plasticGrad.setColorAt(0.60, QColor(28, 29, 35));
    plasticGrad.setColorAt(0.80, QColor(18, 19, 24));
    plasticGrad.setColorAt(1.00, QColor(10, 10, 14));

    p->setPen(Qt::NoPen);
    p->setBrush(plasticGrad);
    p->drawEllipse(c, outerR, outerR);

    // Слой 2: внешний блик (симулирует выпуклость пластика)
    const double hiR = outerR - 1.5;
    QPainterPath outerPath, innerPath;
    outerPath.addEllipse(c, hiR, hiR);
    innerPath.addEllipse(c, faceR + 2.0, faceR + 2.0);
    QPainterPath ring = outerPath.subtracted(innerPath);

    QConicalGradient bevelGrad(c, 60.0);
    bevelGrad.setColorAt(0.00, DS::CHROME_HI);
    bevelGrad.setColorAt(0.18, DS::CHROME_MID);
    bevelGrad.setColorAt(0.38, DS::CHROME_LO);
    bevelGrad.setColorAt(0.52, QColor(15, 15, 20, 160));
    bevelGrad.setColorAt(0.68, DS::CHROME_LO);
    bevelGrad.setColorAt(0.82, DS::CHROME_MID);
    bevelGrad.setColorAt(1.00, DS::CHROME_HI);

    p->setBrush(bevelGrad);
    p->drawPath(ring);

    // Слой 3: тонкая яркая хромовая линия по внешнему краю
    p->setPen(QPen(QColor(130, 132, 140, 120), 0.8));
    p->setBrush(Qt::NoBrush);
    p->drawEllipse(c, outerR - 0.4, outerR - 0.4);

    // Слой 4: тёмная линия разделения рамка/циферблат
    p->setPen(QPen(QColor(5, 5, 8, 240), 2.0));
    p->drawEllipse(c, faceR + 1.5, faceR + 1.5);

    // Слой 5: тонкий внутренний блик рамки
    p->setPen(QPen(QColor(80, 82, 92, 90), 0.8));
    p->drawEllipse(c, faceR + 3.5, faceR + 3.5);
}

// =============================================================================
// Заливка красной зоны: сектор с градиентной прозрачностью
// =============================================================================
void GaugeItem::drawDangerZoneFill(QPainter *p, QPointF c, double faceR, double norm)
{
    const double dangerNorm = m_dangerZone;
    const double arcR       = faceR - 8.0;
    const double arcD       = arcR * 2.0;
    const QRectF arcRect(c.x() - arcR, c.y() - arcR, arcD, arcD);

    const double dangerStart    = ARC_START + ARC_SPAN * dangerNorm;
    const double dangerSpanFull = ARC_SPAN * (1.0 - dangerNorm);

    // Заливка сектора только при попадании в красную зону
    if (norm >= dangerNorm) {
        const double activeSpan = ARC_SPAN * (1.0 - dangerNorm);

        QPainterPath sectorPath;
        sectorPath.moveTo(c);
        sectorPath.arcTo(arcRect,
                         dangerStart,
                         activeSpan);
        sectorPath.closeSubpath();

        QColor fillColor = m_dangerBlink
                               ? QColor(255, 59, 48, 18)
                               : QColor(255, 59, 48, 28);
        p->setPen(Qt::NoPen);
        p->setBrush(fillColor);
        p->drawPath(sectorPath);
    }

    // Постоянная тусклая подсветка красной зоны (всегда видна)
    {
        QPainterPath sectorPath;
        sectorPath.moveTo(c);
        sectorPath.arcTo(arcRect, dangerStart, dangerSpanFull);
        sectorPath.closeSubpath();

        p->setPen(Qt::NoPen);
        p->setBrush(QColor(255, 40, 30, 10));
        p->drawPath(sectorPath);
    }
}

// =============================================================================
// Дуга прогресса: толще, с мягким свечением вдоль
// =============================================================================
void GaugeItem::drawArcTrack(QPainter *p, QPointF c, double faceR, double norm)
{
    const double arcR = faceR - 8.0;
    const double arcD = arcR * 2.0;
    const QRectF arcRect(c.x() - arcR, c.y() - arcR, arcD, arcD);

    const int qtStart = qRound(ARC_START * 16.0);
    const int qtSpan  = qRound(ARC_SPAN  * 16.0);

    // Пассивная дорожка
    QPen passivePen(DS::ARC_PASSIVE, 5.5);
    passivePen.setCapStyle(Qt::FlatCap);
    p->setPen(passivePen);
    p->setBrush(Qt::NoBrush);
    p->drawArc(arcRect, qtStart, qtSpan);

    if (norm <= 0.001) return;

    // Свечение под активной дугой (толще, прозрачнее)
    QColor glowCol;
    if (norm >= m_dangerZone)
        glowCol = QColor(255, 59, 48, 55);
    else if (norm >= m_dangerZone * 0.85)
        glowCol = QColor(255, 160, 0, 40);
    else
        glowCol = QColor(200, 200, 210, 30);

    QPen glowPen(glowCol, 11.0);
    glowPen.setCapStyle(Qt::FlatCap);
    p->setPen(glowPen);
    p->drawArc(arcRect, qtStart, qRound(ARC_SPAN * norm * 16.0));

    // Основная активная дуга
    QColor col;
    if (norm >= m_dangerZone) {
        col = m_dangerBlink ? QColor(255, 59, 48, 80) : DS::CRITICAL;
    } else if (norm >= m_dangerZone * 0.85) {
        const double t = (norm - m_dangerZone * 0.85) / (m_dangerZone * 0.15);
        col = QColor(255, int(200 * (1.0 - t)), 0, 220);
    } else {
        col = QColor(195, 195, 205, 210);
    }

    QPen activePen(col, 5.5);
    activePen.setCapStyle(Qt::FlatCap);
    p->setPen(activePen);
    p->drawArc(arcRect, qtStart, qRound(ARC_SPAN * norm * 16.0));

    // Яркий кончик дуги
    if (norm > 0.02) {
        const double tipAngleDeg = ARC_START + ARC_SPAN * norm;
        const double tipAngleRad = qDegreesToRadians(tipAngleDeg);
        const QPointF tipPt(c.x() + arcR * qCos(tipAngleRad),
                            c.y() - arcR * qSin(tipAngleRad));
        QColor tipCol = (norm >= m_dangerZone) ? DS::CRITICAL : QColor(230, 230, 240);
        p->setPen(Qt::NoPen);
        QRadialGradient tipGlow(tipPt, 8.0);
        tipGlow.setColorAt(0.0, QColor(tipCol.red(), tipCol.green(), tipCol.blue(), 180));
        tipGlow.setColorAt(1.0, QColor(tipCol.red(), tipCol.green(), tipCol.blue(), 0));
        p->setBrush(tipGlow);
        p->drawEllipse(tipPt, 8.0, 8.0);
    }
}

// =============================================================================
// Деления: крупные белее, мелкие тоньше
// =============================================================================
void GaugeItem::drawTicks(QPainter *p, QPointF c, double faceR, double innerR)
{
    if (m_step <= 0) return;

    const bool   isTacho    = (m_maxValue > 999.0);
    const double totalRange  = m_maxValue - m_minValue;
    const double minorStep   = isTacho ? 200.0 : 10.0;
    const int    nMinor      = qRound(totalRange / minorStep);
    const double ringW       = faceR - innerR;

    const double majorLen    = ringW * 0.24;
    const double minorLen    = ringW * 0.12;
    const double microLen    = ringW * 0.07;

    // Начало делений — от края дуги
    const double tickOuterR  = faceR - 12.0;

    for (int i = 0; i <= nMinor; i++) {
        const double frac    = double(i) / double(nMinor);
        const double val     = m_minValue + frac * totalRange;
        const double n       = normalize(val);
        const double angDeg  = ARC_START + ARC_SPAN * n;
        const double angRad  = qDegreesToRadians(angDeg);
        const double ca      = qCos(angRad);
        const double sa      = -qSin(angRad);

        const int ival       = qRound(val);
        bool  isMajor        = false;
        bool  isMid          = false;
        double tLen;
        QColor col;
        double penW;

        if (isTacho) {
            isMajor = (ival % 1000 == 0);
            isMid   = (ival % 500  == 0) && !isMajor;
            if      (isMajor) { tLen = majorLen; col = QColor(210, 210, 218, 210); penW = 1.8; }
            else if (isMid)   { tLen = minorLen; col = QColor(140, 140, 150, 150); penW = 1.0; }
            else              { tLen = microLen; col = QColor( 80,  80,  90,  90); penW = 0.6; }
        } else {
            isMajor = (ival % 20 == 0);
            isMid   = (ival % 10 == 0) && !isMajor;
            if      (isMajor) { tLen = majorLen; col = QColor(210, 210, 218, 210); penW = 1.8; }
            else if (isMid)   { tLen = minorLen; col = QColor(140, 140, 150, 150); penW = 1.0; }
            else              { tLen = microLen; col = QColor( 80,  80,  90,  90); penW = 0.6; }
        }

        // Красная зона: деления ярко-красные
        const double normVal = normalize(val);
        if (normVal >= m_dangerZone) {
            col  = QColor(255, 59, 48, isMajor ? 200 : 120);
            penW = isMajor ? 2.0 : 0.8;
        }

        p->setPen(QPen(col, penW, Qt::SolidLine, Qt::FlatCap));
        p->drawLine(
            QPointF(c.x() + tickOuterR * ca,          c.y() + tickOuterR * sa),
            QPointF(c.x() + (tickOuterR - tLen) * ca, c.y() + (tickOuterR - tLen) * sa)
            );
    }
}

// =============================================================================
// Подписи делений
// =============================================================================
void GaugeItem::drawTickLabels(QPainter *p, QPointF c, double faceR, double innerR)
{
    if (m_step <= 0) return;

    const bool   isTacho    = (m_maxValue > 999.0);
    const double totalRange  = m_maxValue - m_minValue;
    const double minorStep   = isTacho ? 200.0 : 10.0;
    const int    nMinor      = qRound(totalRange / minorStep);
    const double side        = qMin(width(), height());
    const double ringW       = faceR - innerR;
    const double labelR      = innerR + ringW * 0.50;
    const double fontSize    = qMax(5.0, side * 0.030);

    for (int i = 0; i <= nMinor; i++) {
        const double frac  = double(i) / double(nMinor);
        const double val   = m_minValue + frac * totalRange;
        const int    ival  = qRound(val);

        bool shouldLabel = false;
        if (isTacho)  shouldLabel = (ival % 1000 == 0);
        else          shouldLabel = (ival % 20   == 0);
        if (!shouldLabel) continue;

        const double n      = normalize(val);
        const double angDeg = ARC_START + ARC_SPAN * n;
        const double angRad = qDegreesToRadians(angDeg);
        const double ca     = qCos(angRad);
        const double sa     = -qSin(angRad);

        QFont f(FONT, fontSize);
        f.setWeight(QFont::Normal);
        p->setFont(f);

        // Красная зона — метки тоже красноватые
        if (n >= m_dangerZone)
            p->setPen(QColor(255, 80, 70, 180));
        else
            p->setPen(DS::TEXT_SEC);

        const QString txt = isTacho
                                ? QString::number(int(val / 1000))
                                : QString::number(ival);

        QFontMetricsF fm(f);
        QRectF tr = fm.boundingRect(txt);
        tr.moveCenter(QPointF(c.x() + labelR * ca, c.y() + labelR * sa));
        p->drawText(tr, Qt::AlignCenter, txt);
    }

    // Подпись ×1000 для тахометра
    if (isTacho) {
        const double side2 = qMin(width(), height());
        QFont sf(FONT, qMax(3.5, side2 * 0.022));
        p->setFont(sf);
        p->setPen(DS::TEXT_DIM);
        QRectF sr(c.x() - faceR * 0.26, c.y() + innerR * 0.62,
                  faceR * 0.52, side2 * 0.055);
        p->drawText(sr, Qt::AlignCenter, "х1000");
    }
}

// =============================================================================
// Внутренняя дуга (температура ДВС / уровень топлива)
// Расположена в нижней части циферблата, не перекрывает деления
// =============================================================================
void GaugeItem::drawInnerArc(QPainter *p, QPointF c, double innerR)
{
    if (!m_showInnerArc) return;

    const bool   isTemp    = (m_innerArcType == "temp");
    const double norm      = qBound(0.0,
                               (m_innerArcValue - m_innerArcMin) / (m_innerArcMax - m_innerArcMin),
                               1.0);
    const double side      = qMin(width(), height());

    // Радиус дуги: чуть внутрь от innerR
    const double arcR      = innerR * 0.82;
    const double arcD      = arcR * 2.0;
    const QRectF arcRect(c.x() - arcR, c.y() - arcR, arcD, arcD);

    // Дуга расположена в нижней части: от 130° до 50° (через 270°/180°)
    // Qt: 0° = 3 часа, CCW+
    // Нам нужно: от ~8 часов до ~4 часов через низ
    // В Qt-углах: startAngle = -(130°) = 230° → qt = -230*16
    // Но проще: startAngle по нашей системе координат
    // 130° → -(130°-180°) ... используем прямую логику:
    const double arcStartDeg = INNER_ARC_START; // 130° в нашей системе
    const double arcSpanDeg  = INNER_ARC_SPAN;  // -100° (по часовой)

    // Перевод в Qt-систему (Qt: 0°=3ч, CCW+)
    // Наша: 0°=3ч, CW+, Y инвертирован
    const int qtStart = qRound(arcStartDeg * 16.0);
    const int qtSpan  = qRound(arcSpanDeg  * 16.0);  // отрицательный = CW

    // Пассивная дорожка
    QPen passivePen(QColor(50, 50, 60, 160), 3.0);
    passivePen.setCapStyle(Qt::RoundCap);
    p->setPen(passivePen);
    p->setBrush(Qt::NoBrush);
    p->drawArc(arcRect, qtStart, qtSpan);

    // Активная часть
    if (norm > 0.005) {
        QColor activeCol;
        if (isTemp) {
            // Температура: синий→зелёный→жёлтый→красный
            if      (norm < 0.35) activeCol = QColor( 74, 143, 212, 200);  // синий (холодно)
            else if (norm < 0.65) activeCol = QColor( 48, 209,  88, 200);  // зелёный (норма)
            else if (norm < 0.85) activeCol = QColor(255, 204,   0, 200);  // жёлтый (горячо)
            else                  activeCol = QColor(255,  59,  48, 220);  // красный (перегрев)
        } else {
            // Топливо: зелёный→жёлтый→красный
            // Инвертируем: 0 = пусто (красный), 1 = полный (зелёный)
            const double fuelNorm = 1.0 - norm; // для цвета: мало = красный
            if      (fuelNorm < 0.20) activeCol = QColor(255,  59,  48, 220);  // красный (мало)
            else if (fuelNorm < 0.40) activeCol = QColor(255, 204,   0, 200);  // жёлтый
            else                      activeCol = QColor( 48, 209,  88, 200);  // зелёный (много)
        }

        QPen activePen(activeCol, 3.0);
        activePen.setCapStyle(Qt::RoundCap);
        p->setPen(activePen);
        p->drawArc(arcRect, qtStart, qRound(arcSpanDeg * norm * 16.0));
    }

    // Метки внутренней дуги
    const double fontSize  = qMax(3.5, side * 0.022);
    QFont f(FONT, fontSize);
    p->setFont(f);
    p->setPen(DS::TEXT_DIM);

    // Позиции меток: начало, середина, конец дуги
    const double labelR = arcR + 14.0;
    struct Label { double pos; QString text; } labels[3];

    if (isTemp) {
        labels[0] = { 0.0,  "50" };
        labels[1] = { 0.5,  "90" };
        labels[2] = { 1.0, "130" };
    } else {
        labels[0] = { 0.0,  "0" };
        labels[1] = { 0.5, "½" };
        labels[2] = { 1.0,  "1" };
    }

    for (int i = 0; i < 3; i++) {
        const double angDeg = arcStartDeg + arcSpanDeg * labels[i].pos;
        const double angRad = qDegreesToRadians(angDeg);
        const double ca     = qCos(angRad);
        const double sa     = -qSin(angRad);
        QFontMetricsF fm(f);
        QRectF tr = fm.boundingRect(labels[i].text);
        tr.moveCenter(QPointF(c.x() + labelR * ca, c.y() + labelR * sa));
        p->drawText(tr, Qt::AlignCenter, labels[i].text);
    }

    // Пиктограмма под дугой
    const double iconY  = c.y() + arcR * 0.78;
    const double iconSz = side * 0.028;
    p->setPen(QPen(DS::TEXT_DIM, side * 0.006));

    if (isTemp) {
        // Термометр: вертикальный прямоугольник + кружок снизу
        const double tw = iconSz * 0.32;
        const double th = iconSz * 0.65;
        const double tx = c.x() - tw * 0.5;
        const double ty = iconY - th;
        p->setBrush(Qt::NoBrush);
        p->drawRoundedRect(QRectF(tx, ty, tw, th), tw * 0.5, tw * 0.5);
        p->setBrush(DS::TEXT_DIM);
        p->drawEllipse(QPointF(c.x(), iconY + tw * 0.3), tw * 0.55, tw * 0.55);
    } else {
        // Бензоколонка: прямоугольник с трубкой
        const double bw = iconSz * 0.55;
        const double bh = iconSz * 0.72;
        const double bx = c.x() - bw * 0.5;
        const double by = iconY - bh;
        p->setBrush(Qt::NoBrush);
        p->drawRect(QRectF(bx, by, bw, bh));
        // Трубка справа
        p->drawLine(QPointF(bx + bw, by + bh * 0.25),
                    QPointF(bx + bw + bw * 0.55, by + bh * 0.25));
        p->drawLine(QPointF(bx + bw + bw * 0.55, by + bh * 0.25),
                    QPointF(bx + bw + bw * 0.55, by + bh * 0.65));
    }
}

// =============================================================================
// Маленькие индикаторы внутри циферблата
// Расположены симметрично в нижней части, по обе стороны от пиктограммы
// =============================================================================
void GaugeItem::drawInnerIndicators(QPainter *p, QPointF c, double innerR)
{
    if (m_indicator1Icon.isEmpty() && m_indicator2Icon.isEmpty()) return;

    const double side    = qMin(width(), height());
    const double dotR    = side * 0.016;   // радиус точки-индикатора
    const double offsetX = innerR * 0.52;  // горизонтальное смещение от центра
    const double offsetY = innerR * 0.55;  // вертикальное смещение вниз

    const QPointF pos1(c.x() - offsetX, c.y() + offsetY);
    const QPointF pos2(c.x() + offsetX, c.y() + offsetY);

    // Индикатор 1 (левый)
    {
        const QColor bgCol  = m_indicator1Active
                                 ? QColor(255, 59, 48, 200)
                                 : QColor(40, 40, 50, 180);
        const QColor rimCol = m_indicator1Active
                                  ? QColor(255, 59, 48, 255)
                                  : QColor(60, 60, 72, 200);

        p->setPen(QPen(rimCol, side * 0.004));
        p->setBrush(bgCol);
        p->drawEllipse(pos1, dotR * 1.6, dotR * 1.6);

        // Свечение при активном состоянии
        if (m_indicator1Active) {
            QRadialGradient glow(pos1, dotR * 3.5);
            glow.setColorAt(0.0, QColor(255, 59, 48, 60));
            glow.setColorAt(1.0, QColor(255, 59, 48, 0));
            p->setPen(Qt::NoPen);
            p->setBrush(glow);
            p->drawEllipse(pos1, dotR * 3.5, dotR * 3.5);
        }

        // Крестик ремня безопасности (примитивная иконка)
        if (m_indicator1Icon == "seatbelt") {
            p->setPen(QPen(m_indicator1Active ? Qt::white : QColor(80, 80, 90), side * 0.005));
            const double s = dotR * 0.8;
            p->drawLine(QPointF(pos1.x() - s, pos1.y() - s),
                        QPointF(pos1.x() + s, pos1.y() + s));
            p->drawLine(QPointF(pos1.x() + s, pos1.y() - s),
                        QPointF(pos1.x() - s, pos1.y() + s));
        }
    }

    // Индикатор 2 (правый)
    {
        const QColor bgCol  = m_indicator2Active
                                 ? QColor(255, 204, 0, 200)
                                 : QColor(40, 40, 50, 180);
        const QColor rimCol = m_indicator2Active
                                  ? QColor(255, 204, 0, 255)
                                  : QColor(60, 60, 72, 200);

        p->setPen(QPen(rimCol, side * 0.004));
        p->setBrush(bgCol);
        p->drawEllipse(pos2, dotR * 1.6, dotR * 1.6);

        if (m_indicator2Active) {
            QRadialGradient glow(pos2, dotR * 3.5);
            glow.setColorAt(0.0, QColor(255, 204, 0, 60));
            glow.setColorAt(1.0, QColor(255, 204, 0, 0));
            p->setPen(Qt::NoPen);
            p->setBrush(glow);
            p->drawEllipse(pos2, dotR * 3.5, dotR * 3.5);
        }

        // Восклицательный знак (check engine / warning)
        if (m_indicator2Icon == "check" || m_indicator2Icon == "esp") {
            p->setPen(QPen(m_indicator2Active ? Qt::black : QColor(80, 80, 90), side * 0.006));
            const double s = dotR * 0.65;
            p->drawLine(QPointF(pos2.x(), pos2.y() - s),
                        QPointF(pos2.x(), pos2.y() + s * 0.3));
            p->setPen(Qt::NoPen);
            const QColor dotCol = m_indicator2Active ? Qt::black : QColor(80, 80, 90);
            p->setBrush(dotCol);
            p->drawEllipse(QPointF(pos2.x(), pos2.y() + s * 0.75), side * 0.004, side * 0.004);
        }
    }
}

// =============================================================================
// Кольцо свечения
// =============================================================================
void GaugeItem::drawGlowRing(QPainter *p, QPointF c, double innerR)
{
    if (m_glowIntensity <= 0.01) return;

    const int alphaOuter = qRound(m_glowIntensity * 75.0);
    QRadialGradient glowOuter(c, innerR * 1.25);
    glowOuter.setColorAt(0.55, QColor(255, 59, 48, 0));
    glowOuter.setColorAt(0.78, QColor(255, 59, 48, alphaOuter));
    glowOuter.setColorAt(1.00, QColor(255, 59, 48, 0));

    p->setPen(Qt::NoPen);
    p->setBrush(glowOuter);
    p->drawEllipse(c, innerR * 1.25, innerR * 1.25);

    const int alphaInner = qRound(m_glowIntensity * 32.0);
    QRadialGradient glowInner(c, innerR * 0.88);
    glowInner.setColorAt(0.00, QColor(255, 120, 40, alphaInner));
    glowInner.setColorAt(0.55, QColor(255, 80,  20, alphaInner / 2));
    glowInner.setColorAt(1.00, QColor(255, 59,  48, 0));

    p->setBrush(glowInner);
    p->drawEllipse(c, innerR * 0.88, innerR * 0.88);
}

// =============================================================================
// Игла: треугольный силуэт, белая с красным кончиком
// =============================================================================
void GaugeItem::drawNeedle(QPainter *p, QPointF c, double faceR, double innerR, double norm)
{
    const double angDeg = ARC_START + ARC_SPAN * norm;
    const double angRad = qDegreesToRadians(angDeg);
    const double ca     = qCos(angRad);
    const double sa     = -qSin(angRad);

    // Кончик иглы
    const double tipR   = faceR - 14.0;
    const QPointF pTip  (c.x() + tipR * ca, c.y() + tipR * sa);

    // База иглы (у центральной ступицы)
    const double baseR  = innerR * 0.22;
    const QPointF pBase (c.x() - baseR * ca, c.y() - baseR * sa);

    // Перпендикуляр для толщины у основания
    const double baseHalfW = innerR * 0.045;
    const QPointF pLeft (c.x() + baseHalfW * sa,  c.y() + baseHalfW * ca);
    const QPointF pRight(c.x() - baseHalfW * sa,  c.y() - baseHalfW * ca);

    // Тень под иглой
    QPainterPath shadowPath;
    shadowPath.moveTo(pTip + QPointF(2, 2));
    shadowPath.lineTo(pLeft + QPointF(2, 2));
    shadowPath.lineTo(pRight + QPointF(2, 2));
    shadowPath.closeSubpath();
    p->setPen(Qt::NoPen);
    p->setBrush(QColor(0, 0, 0, 60));
    p->drawPath(shadowPath);

    // Основная игла (треугольник)
    QPainterPath needlePath;
    needlePath.moveTo(pTip);
    needlePath.lineTo(pLeft);
    needlePath.lineTo(pRight);
    needlePath.closeSubpath();

    // Градиент вдоль иглы: основание светлее, кончик ярче
    QLinearGradient needleGrad(pBase, pTip);
    needleGrad.setColorAt(0.00, QColor(200, 200, 210, 220));
    needleGrad.setColorAt(0.65, QColor(225, 225, 235, 235));
    needleGrad.setColorAt(0.85, QColor(240, 240, 248, 245));
    needleGrad.setColorAt(1.00, DS::CRITICAL);  // красный кончик

    p->setBrush(needleGrad);
    p->setPen(QPen(QColor(30, 30, 40, 180), 0.5));
    p->drawPath(needlePath);

    // Яркое свечение на кончике иглы
    QRadialGradient tipGlow(pTip, 10.0);
    tipGlow.setColorAt(0.0, QColor(255, 80, 60, 160));
    tipGlow.setColorAt(1.0, QColor(255, 59, 48, 0));
    p->setPen(Qt::NoPen);
    p->setBrush(tipGlow);
    p->drawEllipse(pTip, 10.0, 10.0);
}

// =============================================================================
// Центральная ступица
// =============================================================================
void GaugeItem::drawCenterHub(QPainter *p, QPointF c)
{
    const double side = qMin(width(), height());
    const double hubR = side * 0.032;

    // Внешнее кольцо ступицы
    QRadialGradient hubBg(c, hubR);
    hubBg.setFocalPoint(QPointF(c.x() - hubR * 0.3, c.y() - hubR * 0.3));
    hubBg.setColorAt(0.00, QColor(55, 56, 65));
    hubBg.setColorAt(0.60, QColor(28, 29, 36));
    hubBg.setColorAt(1.00, QColor(15, 15, 20));

    p->setPen(Qt::NoPen);
    p->setBrush(hubBg);
    p->drawEllipse(c, hubR, hubR);

    // Хромовый ободок ступицы
    QConicalGradient hubRim(c, 45.0);
    hubRim.setColorAt(0.00, QColor(100, 102, 112, 200));
    hubRim.setColorAt(0.25, QColor( 50,  52,  60, 180));
    hubRim.setColorAt(0.50, QColor(120, 122, 132, 200));
    hubRim.setColorAt(0.75, QColor( 40,  42,  50, 160));
    hubRim.setColorAt(1.00, QColor(100, 102, 112, 200));

    p->setPen(QPen(hubRim, side * 0.006));
    p->setBrush(Qt::NoBrush);
    p->drawEllipse(c, hubR, hubR);

    // Центральная точка
    p->setPen(Qt::NoPen);
    p->setBrush(QColor(70, 72, 82));
    p->drawEllipse(c, hubR * 0.28, hubR * 0.28);
}

// =============================================================================
// Центральный текст
// =============================================================================
void GaugeItem::drawCenterText(QPainter *p, QPointF c, double innerR, double norm)
{
    const double side = qMin(width(), height());

    if (!m_centerText.isEmpty()) {
        // Тахометр: передача
        QFont gf(FONT, qMax(8.0, innerR * 0.50));
        gf.setWeight(QFont::Normal);
        p->setFont(gf);
        p->setPen(DS::TEXT_PRIMARY);

        const QRectF r(c.x() - innerR * 0.60, c.y() - innerR * 0.44,
                       innerR * 1.20, innerR * 0.88);
        p->drawText(r, Qt::AlignCenter, m_centerText);

    } else {
        // Спидометр
        QColor numCol;
        const double speed = m_value;
        if      (speed > 240) numCol = DS::CRITICAL;
        else if (speed > 200) numCol = QColor(255, 179, 0);
        else if (speed > 150) numCol = DS::WARNING;
        else                  numCol = DS::TEXT_PRIMARY;

        const QString speedStr  = QString::number(int(m_value));
        const bool threeDigits  = (speedStr.length() >= 3);
        const double numFontSize = threeDigits
                                       ? qMax(8.0, innerR * 0.42)
                                       : qMax(8.0, innerR * 0.52);

        QFont nf(FONT, numFontSize);
        nf.setWeight(QFont::Normal);
        p->setFont(nf);
        p->setPen(numCol);

        const QRectF numR(c.x() - innerR * 0.86, c.y() - innerR * 0.44,
                          innerR * 1.72, innerR * 0.88);
        p->drawText(numR, Qt::AlignCenter, speedStr);

        if (!m_unit.isEmpty()) {
            QFont uf(FONT, qMax(3.0, side * 0.022));
            uf.setLetterSpacing(QFont::AbsoluteSpacing, 1.2);
            p->setFont(uf);
            p->setPen(DS::TEXT_DIM);
            const QRectF unitR(c.x() - innerR * 0.52, c.y() + innerR * 0.44,
                               innerR * 1.04, side * 0.058);
            p->drawText(unitR, Qt::AlignCenter, m_unit);
        }
    }
}
