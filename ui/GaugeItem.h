#pragma once

// =============================================================================
// GaugeItem.h — QPainter-компонент циферблата (спидометр / тахометр)
//
// Финальный OEM-уровень. Ключевые решения:
//
//   ГЕОМЕТРИЯ:
//     outerR = side * 0.450   — внешний край зоны делений
//     innerR = side * 0.280   — граница центрального дисплея
//     arcR   = outerR - 10    — дуга прогресса (тонкая, у внешнего края)
//     arcW   = 4px            — толщина дуги (минимальная, OEM-стиль)
//
//   ИГЛА:
//     • Линия 1.0px, цвет #FFFFFF (читаемее красного на тёмном фоне)
//     • Glow только на кончике: 3 круга 4/2/1px, alpha 30/15/5
//     • Красная точка 2px на острие — единственный цветной акцент
//     • Хвост 8% от innerR — небольшой противовес
//
//   ЦЕНТРАЛЬНЫЙ ДИСПЛЕЙ (тахометр):
//     • Только передача — крупно, центрировано
//     • Никаких вторичных данных в тахометре
//
//   ПРОИЗВОДИТЕЛЬНОСТЬ:
//     • setRenderTarget(FBO) — GPU-ускорение
//     • qFuzzyCompare перед update() — нет лишних перерисовок
//     • Все вспомогательные методы private
// =============================================================================

#include <QQuickPaintedItem>
#include <QPainter>
#include <QImage>

class GaugeItem : public QQuickPaintedItem
{
    Q_OBJECT

    // Значение и диапазон
    Q_PROPERTY(double  value       READ value       WRITE setValue       NOTIFY valueChanged)
    Q_PROPERTY(double  minValue    READ minValue    WRITE setMinValue    NOTIFY minValueChanged)
    Q_PROPERTY(double  maxValue    READ maxValue    WRITE setMaxValue    NOTIFY maxValueChanged)
    Q_PROPERTY(double  step        READ step        WRITE setStep        NOTIFY stepChanged)

    // Цвет дуги (передаётся из Gauge.qml, соответствует Design System)
    Q_PROPERTY(QColor  arcColor    READ arcColor    WRITE setArcColor    NOTIFY arcColorChanged)

    // Порог опасной зоны [0.0–1.0]
    Q_PROPERTY(double  dangerZone  READ dangerZone  WRITE setDangerZone  NOTIFY dangerZoneChanged)

    // Единица измерения под числом спидометра (например "km/h")
    Q_PROPERTY(QString unit        READ unit        WRITE setUnit        NOTIFY unitChanged)

    // Текст в центре тахометра (передача: "1"…"6", "N", "P")
    Q_PROPERTY(QString centerText  READ centerText  WRITE setCenterText  NOTIFY centerTextChanged)

    // Интенсивность свечения ring [0.0–1.0], привязана к rpm/maxRpm
    Q_PROPERTY(double  glowIntensity READ glowIntensity WRITE setGlowIntensity NOTIFY glowIntensityChanged)

    // Мигание в опасной зоне — управляется единым QML-таймером (Gauge.qml)
    Q_PROPERTY(bool    dangerBlink READ dangerBlink  WRITE setDangerBlink NOTIFY dangerBlinkChanged)

public:
    explicit GaugeItem(QQuickItem *parent = nullptr);
    void paint(QPainter *painter) override;

    double  value()         const { return m_value; }
    double  minValue()      const { return m_minValue; }
    double  maxValue()      const { return m_maxValue; }
    double  step()          const { return m_step; }
    QColor  arcColor()      const { return m_arcColor; }
    double  dangerZone()    const { return m_dangerZone; }
    QString unit()          const { return m_unit; }
    QString centerText()    const { return m_centerText; }
    double  glowIntensity() const { return m_glowIntensity; }
    bool    dangerBlink()   const { return m_dangerBlink; }

    void setValue(double v);
    // Изменение диапазона/шага инвалидирует кэш статического слоя (деления+подписи)
    void setMinValue(double v)        { m_minValue = v;  m_staticDirty = true; emit minValueChanged();  update(); }
    void setMaxValue(double v)        { m_maxValue = v;  m_staticDirty = true; emit maxValueChanged();  update(); }
    void setStep(double v)            { m_step = v;      m_staticDirty = true; emit stepChanged();      update(); }
    void setArcColor(const QColor &v) { m_arcColor = v;  emit arcColorChanged();  update(); }
    void setDangerZone(double v)      { m_dangerZone = v; emit dangerZoneChanged(); update(); }
    void setUnit(const QString &v)    { m_unit = v;      emit unitChanged();      update(); }
    void setCenterText(const QString &v){ if (m_centerText == v) return; m_centerText = v; emit centerTextChanged(); update(); }
    // Свечение: пропускаем неощутимые изменения, чтобы не плодить перерисовки
    void setGlowIntensity(double v)   { if (qAbs(m_glowIntensity - v) < 0.004) return; m_glowIntensity = v; emit glowIntensityChanged(); update(); }
    void setDangerBlink(bool v)       { if (m_dangerBlink == v) return; m_dangerBlink = v; emit dangerBlinkChanged(); update(); }

signals:
    void valueChanged();
    void minValueChanged();
    void maxValueChanged();
    void stepChanged();
    void arcColorChanged();
    void dangerZoneChanged();
    void unitChanged();
    void centerTextChanged();
    void glowIntensityChanged();
    void dangerBlinkChanged();

private:
    // Геометрия дуги
    // ARC_START = 225° — начало шкалы (7 часов)
    // ARC_SPAN  = -270° — дуга 270° по часовой стрелке
    // Итог: шкала от 225° до 225°-270° = -45° (5 часов)
    static constexpr double ARC_START = 225.0;
    static constexpr double ARC_SPAN  = -270.0;

    // Шрифт
    static constexpr auto FONT = "Microgramma";

    // Конвертация значения в нормализованную позицию [0–1]
    double normalize(double v) const;

    // Слои рисования (вызываются строго по порядку)
    void drawBackground  (QPainter *p, QPointF c, double outerR, double innerR);
    void drawArcTrack    (QPainter *p, QPointF c, double outerR, double norm);
    void drawTicks       (QPainter *p, QPointF c, double outerR, double innerR);
    void drawTickLabels  (QPainter *p, QPointF c, double outerR, double innerR);
    void drawGlowRing    (QPainter *p, QPointF c, double innerR);
    void drawNeedle      (QPainter *p, QPointF c, double outerR, double innerR, double norm);
    void drawCenterHub   (QPainter *p, QPointF c);
    void drawCenterText  (QPainter *p, QPointF c, double innerR, double norm);

    double  m_value         = 0.0;
    double  m_minValue      = 0.0;
    double  m_maxValue      = 300.0;
    double  m_step          = 20.0;
    QColor  m_arcColor      { "#FF3B30" };
    double  m_dangerZone    = 0.85;
    QString m_unit;
    QString m_centerText;
    double  m_glowIntensity = 0.0;
    bool    m_dangerBlink   = false;

    // Кэш статического слоя: фон + деления + подписи.
    // Перерисовывается только при изменении размера или диапазона/шага,
    // а не на каждый кадр (игла/дуга/свечение/передача рисуются поверх).
    QImage  m_staticLayer;
    bool    m_staticDirty   = true;
};
