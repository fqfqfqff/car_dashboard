#include "GaugeItem.h"

#include <QtMath>
#include <QPainterPath>
#include <QRadialGradient>
#include <QConicalGradient>
#include <QFontMetricsF>
#include <QQuickWindow>

// =============================================================================
// Цветовые константы (зеркало DesignSystem.qml для C++ слоя)
// =============================================================================
namespace DS {
static const QColor BG_PRIMARY   {  10,  10,  10 };
static const QColor BG_SECONDARY {  18,  18,  18 };
static const QColor BG_SURFACE   {  26,  26,  26 };
static const QColor TEXT_PRIMARY { 255, 255, 255, 230 };
static const QColor TEXT_SEC     { 176, 176, 176 };
static const QColor TEXT_DIM     { 106, 106, 106 };
static const QColor CRITICAL     { 255,  59,  48 };
static const QColor WARNING      { 255, 204,   0 };
static const QColor INFO_GREEN   {  48, 209,  88 };
static const QColor ARC_PASSIVE  {  48,  48,  48, 160 };
static const QColor DIVIDER      {  36,  36,  36 };
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

// =============================================================================
// Нормализация: значение → [0.0 … 1.0] для позиции иглы
//
// Спидометр (maxValue ≤ 999):
//   Нелинейная: центр шкалы на 100 км/ч.
//   Это реалистично: большинство езды в диапазоне 0–120 км/ч,
//   поэтому там больше "места" на шкале.
//
// Тахометр (maxValue > 999):
//   Строго линейный.
// =============================================================================
double GaugeItem::normalize(double v) const
{
    const bool isTacho = (m_maxValue > 999.0);
    if (isTacho) {
        return (v - m_minValue) / (m_maxValue - m_minValue);
    }
    const double center = 100.0;
    if (v <= center)
        return 0.5 * (v - m_minValue) / (center - m_minValue);
    return 0.5 + 0.5 * (v - center) / (m_maxValue - center);
}

// =============================================================================
// Главная функция отрисовки
// =============================================================================
void GaugeItem::paint(QPainter *painter)
{
    painter->setRenderHint(QPainter::Antialiasing,          true);
    painter->setRenderHint(QPainter::TextAntialiasing,      true);
    painter->setRenderHint(QPainter::SmoothPixmapTransform, true);

    const double side   = qMin(width(), height());
    const QPointF center(width() / 2.0, height() / 2.0);

    // ── Радиусы ───────────────────────────────────────────────────────────────
    // Между innerR и outerR — зона делений (широкая, много воздуха)
    const double outerR = side * 0.450;   // граница зоны делений
    const double innerR = side * 0.280;   // граница центрального дисплея

    const double norm = qBound(0.0, normalize(m_value), 1.0);

    // ── Статический слой (фон + деления + подписи) ──────────────────────────────
    // Эти элементы зависят только от размера и диапазона, поэтому рисуем их один раз
    // в QImage-кэш и затем просто копируем. Экономит дорогой рендер текста подписей
    // и десятки линий делений на КАЖДОМ кадре движения.
    const qreal dpr  = window() ? window()->effectiveDevicePixelRatio() : 1.0;
    const QSize phys(qMax(1, int(qCeil(width()  * dpr))),
                     qMax(1, int(qCeil(height() * dpr))));

    if (m_staticDirty || m_staticLayer.size() != phys) {
        m_staticLayer = QImage(phys, QImage::Format_ARGB32_Premultiplied);
        m_staticLayer.setDevicePixelRatio(dpr);
        m_staticLayer.fill(Qt::transparent);

        QPainter sp(&m_staticLayer);
        sp.setRenderHint(QPainter::Antialiasing,     true);
        sp.setRenderHint(QPainter::TextAntialiasing, true);
        drawBackground (&sp, center, outerR, innerR);
        drawTicks      (&sp, center, outerR, innerR);
        drawTickLabels (&sp, center, outerR, innerR);
        m_staticDirty = false;
    }
    painter->drawImage(0, 0, m_staticLayer);

    // ── Динамические слои (каждый кадр) ─────────────────────────────────────────
    drawArcTrack    (painter, center, outerR, norm);
    drawGlowRing    (painter, center, innerR);
    drawNeedle      (painter, center, outerR, innerR, norm);
    drawCenterText  (painter, center, innerR, norm);
}

// =============================================================================
// Фон: матовый тёмный круг + тонкое кольцо-ободок
// Принцип: ничего хромированного, никакого блеска
// =============================================================================
void GaugeItem::drawBackground(QPainter *p, QPointF c,
                               double outerR, double /*innerR*/)
{
    const double maxR = qMin(width(), height()) * 0.496;
    const double bgR  = qMin(outerR * 1.055, maxR);

    // Матовый тёмный фон: очень слабый радиальный градиент
    // Центр чуть светлее — создаёт ощущение глубины без блеска
    QRadialGradient bg(c, bgR);
    bg.setColorAt(0.0, DS::BG_SECONDARY);
    bg.setColorAt(0.7, DS::BG_PRIMARY);
    bg.setColorAt(1.0, QColor(4, 4, 4));

    p->setPen(Qt::NoPen);
    p->setBrush(bg);
    p->drawEllipse(c, bgR, bgR);

    // Тонкий ободок (тёмный алюминий, не хром)
    p->setPen(QPen(QColor(44, 44, 44, 140), 1.2));
    p->setBrush(Qt::NoBrush);
    p->drawEllipse(c, bgR - 0.6, bgR - 0.6);

    // Разделительная линия внешней границы зоны делений
    p->setPen(QPen(DS::DIVIDER, 1.0));
    p->drawEllipse(c, outerR, outerR);
}

// =============================================================================
// Дуга прогресса: пассивная дорожка + активная часть
//
// Геометрия:
//   arcR = outerR - 10   — у внешнего края, не в центре зоны делений
//   arcW = 4px           — минимальная толщина
//
// Цветовые зоны:
//   0–dangerZone*0.85    → нейтральная (светло-серая)
//   dangerZone*0.85–0.85 → переход к жёлтому
//   >dangerZone          → красный (с миганием через dangerBlink)
// =============================================================================
void GaugeItem::drawArcTrack(QPainter *p, QPointF c, double outerR, double norm)
{
    const double arcR = outerR - 10.0;   // у внешнего края зоны делений
    const double arcW = 4.0;             // OEM-тонкость
    const double arcD = arcR * 2.0;

    const QRectF arcRect(c.x() - arcR, c.y() - arcR, arcD, arcD);

    // Qt drawArc: angles в 1/16 градуса; 0° = 3 часа; CCW = +
    const int qtStart = qRound(ARC_START * 16.0);
    const int qtSpan  = qRound(ARC_SPAN  * 16.0);

    // Пассивная дорожка (весь диапазон)
    QPen passivePen(DS::ARC_PASSIVE, arcW);
    passivePen.setCapStyle(Qt::FlatCap);
    p->setPen(passivePen);
    p->setBrush(Qt::NoBrush);
    p->drawArc(arcRect, qtStart, qtSpan);

    // Активная часть
    if (norm > 0.001) {
        QColor col;
        if (norm >= m_dangerZone) {
            // Критическая зона: красный, с миганием (dangerBlink от QML-таймера)
            col = m_dangerBlink ? QColor(255, 59, 48, 60) : DS::CRITICAL;
        } else if (norm >= m_dangerZone * 0.85) {
            // Переходная зона: плавный градиент жёлтый → красный
            const double t = (norm - m_dangerZone * 0.85) / (m_dangerZone * 0.15);
            col = QColor(255, int(204 * (1.0 - t)), 0, 215);
        } else {
            // Нормальная зона: тихий серебристый (не белый — не конкурирует с делениями)
            col = QColor(180, 180, 180, 190);
        }

        QPen activePen(col, arcW);
        activePen.setCapStyle(Qt::FlatCap);
        p->setPen(activePen);
        p->drawArc(arcRect, qtStart, qRound(ARC_SPAN * norm * 16.0));
    }
}

// =============================================================================
// Деления шкалы
//
// Спидометр: крупные каждые 20 км/ч, мелкие каждые 10 км/ч
// Тахометр:  крупные каждые 1000 об/мин, мелкие каждые 200
//
// Стиль: тонкие, минималистичные, внутри зоны outerR–innerR
//        (не перекрывают дугу и не заходят в дисплей)
// =============================================================================
void GaugeItem::drawTicks(QPainter *p, QPointF c,
                          double outerR, double innerR)
{
    if (m_step <= 0) return;

    const bool   isTacho   = (m_maxValue > 999.0);
    const double totalRange = m_maxValue - m_minValue;
    const double minorStep  = isTacho ? 200.0 : 10.0;
    const int    nMinor     = qRound(totalRange / minorStep);
    const double ringW      = outerR - innerR;

    // Длины рисок (от внешнего края innerR внутрь)
    const double majorLen = ringW * 0.20;   // крупная: 20% ширины кольца
    const double minorLen = ringW * 0.10;   // мелкая:  10%

    for (int i = 0; i <= nMinor; i++) {
        const double frac   = double(i) / double(nMinor);
        const double val    = m_minValue + frac * totalRange;
        const double n      = normalize(val);
        const double angDeg = ARC_START + ARC_SPAN * n;
        const double angRad = qDegreesToRadians(angDeg);
        const double ca     = qCos(angRad);
        const double sa     = -qSin(angRad);

        const int ival   = qRound(val);
        bool  isMajor    = false;
        double tLen      = minorLen;
        QColor col;

        if (isTacho) {
            isMajor = (ival % 1000 == 0);
            tLen    = isMajor ? majorLen : minorLen;
            col     = isMajor ? QColor(190, 190, 190, 185)
                          : QColor(110, 110, 110, 100);
        } else {
            isMajor = (ival % 20 == 0);
            tLen    = isMajor ? majorLen : minorLen;
            col     = isMajor ? QColor(185, 185, 185, 180)
                          : QColor(100, 100, 100, 95);
        }

        // Деления начинаются от границы дуги и идут внутрь
        // r1 чуть внутрь от outerR (чтобы не перекрывать дугу)
        const double r1 = outerR - 14.0;
        const double r2 = r1 - tLen;

        p->setPen(QPen(col, isMajor ? 1.4 : 0.75));
        p->drawLine(
            QPointF(c.x() + r1 * ca, c.y() + r1 * sa),
            QPointF(c.x() + r2 * ca, c.y() + r2 * sa)
            );
    }
}

// =============================================================================
// Подписи делений — #B0B0B0, некрупный шрифт
// Размещены посредине зоны делений (между дугой и innerR)
// =============================================================================
void GaugeItem::drawTickLabels(QPainter *p, QPointF c,
                               double outerR, double innerR)
{
    if (m_step <= 0) return;

    const bool   isTacho   = (m_maxValue > 999.0);
    const double totalRange = m_maxValue - m_minValue;
    const double minorStep  = isTacho ? 200.0 : 10.0;
    const int    nMinor     = qRound(totalRange / minorStep);
    const double side       = qMin(width(), height());
    const double ringW      = outerR - innerR;

    const double labelR = innerR + ringW * 0.28;
    const double fontSize = qMax(4.0, side * 0.023);

    for (int i = 0; i <= nMinor; i++) {
        const double frac = double(i) / double(nMinor);
        const double val  = m_minValue + frac * totalRange;
        const int    ival = qRound(val);

        bool shouldLabel = false;
        if (isTacho) {
            shouldLabel = (ival % 1000 == 0);
        } else {
            if (ival < 100)
                shouldLabel = (ival % 20 == 0);
            else
                shouldLabel = ((ival - 100) % 40 == 0);
        }
        if (!shouldLabel) continue;

        const double n      = normalize(val);
        const double angDeg = ARC_START + ARC_SPAN * n;
        const double angRad = qDegreesToRadians(angDeg);
        const double ca     = qCos(angRad);
        const double sa     = -qSin(angRad);

        QFont f(FONT, fontSize);
        f.setWeight(QFont::Normal);
        p->setFont(f);
        p->setPen(DS::TEXT_SEC);   // #B0B0B0 — вторичный, не конкурирует

        const QString txt = isTacho
                                ? QString::number(qRound(val / 1000.0))
                                : QString::number(ival);

        QFontMetricsF fm(f);
        QRectF tr = fm.boundingRect(txt);
        tr.moveCenter(QPointF(c.x() + labelR * ca, c.y() + labelR * sa));
        p->drawText(tr, Qt::AlignCenter, txt);
    }

    // Подпись единицы тахометра "×1000" — очень мелко, под центром
    if (isTacho) {
        const double side2 = qMin(width(), height());
        QFont sf(FONT, qMax(3.0, side2 * 0.021));
        p->setFont(sf);
        p->setPen(DS::TEXT_DIM);
        QRectF sr(c.x() - outerR * 0.28, c.y() + innerR * 0.58,
                  outerR * 0.56, side2 * 0.05);
        p->drawText(sr, Qt::AlignCenter, "х1000");
    }
}

// =============================================================================
// Кольцо свечения у innerR (пульсирует с оборотами)
// Очень слабое, не броское: max alpha = 50
// =============================================================================
// Красная подсветка: оттенки красного, ярче с ростом оборотов
static QColor glowRamp(double x)
{
    struct Stop { double p; int r, g, b; };
    static const Stop s[] = {
        { 0.00, 200,  44,  36 },   // тёмно-красный (низкие обороты)
        { 0.45, 235,  54,  44 },
        { 0.75, 255,  64,  52 },
        { 1.00, 255,  82,  64 },   // ярко-красный (отсечка)
    };
    const int n = 4;
    if (x <= s[0].p) return QColor(s[0].r, s[0].g, s[0].b);
    for (int i = 1; i < n; ++i) {
        if (x <= s[i].p) {
            const double f = (x - s[i-1].p) / (s[i].p - s[i-1].p);
            return QColor(int(s[i-1].r + (s[i].r - s[i-1].r) * f),
                          int(s[i-1].g + (s[i].g - s[i-1].g) * f),
                          int(s[i-1].b + (s[i].b - s[i-1].b) * f));
        }
    }
    return QColor(s[n-1].r, s[n-1].g, s[n-1].b);
}

void GaugeItem::drawGlowRing(QPainter *p, QPointF c, double innerR)
{
    const double t = qBound(0.0, m_glowIntensity, 1.0);
    if (t <= 0.01) return;

    const QColor gc = glowRamp(t);
    const int R = gc.red(), G = gc.green(), B = gc.blue();

    p->setPen(Qt::NoPen);

    // Широкое мягкое внешнее гало — много стопов для плавного затухания
    const double rOuter = innerR * 1.40;
    const int aMax = qMin(255, qRound(t * 120.0));
    QRadialGradient glowOuter(c, rOuter);
    glowOuter.setColorAt(0.32, QColor(R, G, B, 0));
    glowOuter.setColorAt(0.48, QColor(R, G, B, aMax / 6));
    glowOuter.setColorAt(0.60, QColor(R, G, B, aMax / 3));
    glowOuter.setColorAt(0.70, QColor(R, G, B, aMax / 2));
    glowOuter.setColorAt(0.79, QColor(R, G, B, aMax));
    glowOuter.setColorAt(0.87, QColor(R, G, B, aMax / 2));
    glowOuter.setColorAt(0.94, QColor(R, G, B, aMax / 5));
    glowOuter.setColorAt(1.00, QColor(R, G, B, 0));
    p->setBrush(glowOuter);
    p->drawEllipse(c, rOuter, rOuter);

    // Внутреннее тёплое ядро — лёгкая заливка к центру
    const double rInner = innerR * 1.05;
    const int aIn = qMin(255, qRound(t * 52.0));
    const QColor core = gc.lighter(125);
    QRadialGradient glowInner(c, rInner);
    glowInner.setColorAt(0.00, QColor(core.red(), core.green(), core.blue(), aIn));
    glowInner.setColorAt(0.35, QColor(core.red(), core.green(), core.blue(), aIn * 3 / 4));
    glowInner.setColorAt(0.62, QColor(R, G, B, aIn / 2));
    glowInner.setColorAt(0.82, QColor(R, G, B, aIn / 4));
    glowInner.setColorAt(1.00, QColor(R, G, B, 0));
    p->setBrush(glowInner);
    p->drawEllipse(c, rInner, rInner);
}

// =============================================================================
// Игла — OEM-финальный стиль:
//
//   • Линия 1.0px, цвет #EBEBEB (почти белый — лучше читается на тёмном)
//   • Glow только на кончике: 3 уровня (tighter, not full-length)
//   • Красная точка 2.2px на острие
//   • Хвост: 8% от innerR — минимальный противовес
//   • Центральная ступица: 5px, матовая тёмная
// =============================================================================
void GaugeItem::drawNeedle(QPainter *p, QPointF c,
                           double outerR, double innerR, double norm)
{
    // Угол иглы
    const double angDeg = ARC_START + ARC_SPAN * norm;
    const double angRad = qDegreesToRadians(angDeg);
    const double ca = qCos(angRad);
    const double sa = -qSin(angRad);

    // Конец и начало линии
    const QPointF pTip  (c.x() + (outerR - 16.0) * ca, c.y() + (outerR - 16.0) * sa);
    const QPointF pBase (c.x() + (innerR + 2.0) * ca, c.y() + (innerR + 2.0) * sa);


    // ── Основная игла: белая линия
    QPen needlePen(QColor(235, 235, 235, 235), 1.5);
    needlePen.setCapStyle(Qt::RoundCap);
    p->setPen(needlePen);
    p->drawLine(pBase, pTip);
}


// =============================================================================
// Центральная ступица (скрывает место соединения иглы и хвоста)
// =============================================================================
// void GaugeItem::drawCenterHub(QPainter *p, QPointF c)
// {
//     // Тёмный круг: скрывает основание иглы
//     p->setPen(Qt::NoPen);
//     p->setBrush(DS::BG_SECONDARY);
//     p->drawEllipse(c, 5.5, 5.5);

//     // Тонкий ободок ступицы
//     p->setPen(QPen(QColor(70, 70, 70, 160), 0.8));
//     p->setBrush(Qt::NoBrush);
//     p->drawEllipse(c, 5.5, 5.5);
// }

// =============================================================================
// Центральный текст
//
// Тахометр: только передача (крупно, по центру)
//   Цвет: TEXT_PRIMARY (нейтральный)
//
// Спидометр: число скорости + единица
//   Цвет числа: по зоне (белый → жёлтый → красный)
//   Единица: TEXT_DIM (не конкурирует с числом)
// =============================================================================
void GaugeItem::drawCenterText(QPainter *p, QPointF c, double innerR, double /*norm*/)
{
    const double side = qMin(width(), height());

    if (!m_centerText.isEmpty()) {
        // ── ТАХОМЕТР: передача ──────────────────────────────────────────────
        QFont gf(FONT, qMax(8.0, innerR * 0.52));
        gf.setWeight(QFont::Normal);
        p->setFont(gf);
        p->setPen(DS::TEXT_PRIMARY);

        const QRectF r(c.x() - innerR * 0.62, c.y() - innerR * 0.42,
                       innerR * 1.24, innerR * 0.84);
        p->drawText(r, Qt::AlignCenter, m_centerText);

    } else {
        // ── СПИДОМЕТР: скорость + единица ───────────────────────────────────

        // Цвет по зоне
        QColor numCol;
        double speed = m_value;  // текущая скорость

        if (speed > 240)        numCol = DS::CRITICAL;      // красный
        else if (speed > 200)   numCol = QColor(255, 179, 0);   // оранжевый (#FFB300)
        else if (speed > 150)   numCol = DS::WARNING;       // жёлтый (#FFCC00)
        else                    numCol = DS::TEXT_PRIMARY;  // белый                 numCol = DS::TEXT_PRIMARY;  // белый                               numCol = DS::TEXT_PRIMARY;

        // Число скорости — главный элемент
        // Для 3-значных чисел (100+) уменьшаем шрифт чтобы не вылезать за innerR
        const QString speedStr = QString::number(int(m_value));
        const bool threeDigits = (speedStr.length() >= 3);
        const double numFontSize = threeDigits
                                       ? qMax(8.0, innerR * 0.38)
                                       : qMax(8.0, innerR * 0.52);
        QFont nf(FONT, numFontSize);
        nf.setWeight(QFont::Normal);
        p->setFont(nf);
        p->setPen(numCol);

        // Прямоугольник шире, чтобы 3 цифры гарантированно влезали
        const QRectF numR(c.x() - innerR * 0.88, c.y() - innerR * 0.44,
                          innerR * 1.76, innerR * 0.88);
        p->drawText(numR, Qt::AlignCenter, speedStr);

        // Единица — мелко и приглушённо
        if (!m_unit.isEmpty()) {
            QFont uf(FONT, qMax(3.0, side * 0.024));
            uf.setLetterSpacing(QFont::AbsoluteSpacing, 1.5);
            p->setFont(uf);
            p->setPen(DS::TEXT_DIM);

            const QRectF unitR(c.x() - innerR * 0.55, c.y() + innerR * 0.46,
                               innerR * 1.10, side * 0.060);
            p->drawText(unitR, Qt::AlignCenter, m_unit);
        }
    }
}
