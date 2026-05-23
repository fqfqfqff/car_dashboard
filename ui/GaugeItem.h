#pragma once

#include <QQuickPaintedItem>
#include <QPainter>

class GaugeItem : public QQuickPaintedItem
{
    Q_OBJECT

    Q_PROPERTY(double  value          READ value          WRITE setValue          NOTIFY valueChanged)
    Q_PROPERTY(double  minValue       READ minValue       WRITE setMinValue       NOTIFY minValueChanged)
    Q_PROPERTY(double  maxValue       READ maxValue       WRITE setMaxValue       NOTIFY maxValueChanged)
    Q_PROPERTY(double  step           READ step           WRITE setStep           NOTIFY stepChanged)
    Q_PROPERTY(QColor  arcColor       READ arcColor       WRITE setArcColor       NOTIFY arcColorChanged)
    Q_PROPERTY(double  dangerZone     READ dangerZone     WRITE setDangerZone     NOTIFY dangerZoneChanged)
    Q_PROPERTY(QString unit           READ unit           WRITE setUnit           NOTIFY unitChanged)
    Q_PROPERTY(QString centerText     READ centerText     WRITE setCenterText     NOTIFY centerTextChanged)
    Q_PROPERTY(double  glowIntensity  READ glowIntensity  WRITE setGlowIntensity  NOTIFY glowIntensityChanged)
    Q_PROPERTY(bool    dangerBlink    READ dangerBlink    WRITE setDangerBlink    NOTIFY dangerBlinkChanged)

    // Внутренняя дуга (температура ДВС для тахометра, топливо для спидометра)
    Q_PROPERTY(double  innerArcValue  READ innerArcValue  WRITE setInnerArcValue  NOTIFY innerArcValueChanged)
    Q_PROPERTY(double  innerArcMin    READ innerArcMin    WRITE setInnerArcMin    NOTIFY innerArcMinChanged)
    Q_PROPERTY(double  innerArcMax    READ innerArcMax    WRITE setInnerArcMax    NOTIFY innerArcMaxChanged)
    Q_PROPERTY(bool    showInnerArc   READ showInnerArc   WRITE setShowInnerArc   NOTIFY showInnerArcChanged)
    // "temp" = дуга температуры ДВС (синий→зелёный→красный)
    // "fuel" = дуга топлива (зелёный→красный слева)
    Q_PROPERTY(QString innerArcType   READ innerArcType   WRITE setInnerArcType   NOTIFY innerArcTypeChanged)

    // Маленькие индикаторы внутри циферблата
    Q_PROPERTY(bool    indicator1Active READ indicator1Active WRITE setIndicator1Active NOTIFY indicator1ActiveChanged)
    Q_PROPERTY(bool    indicator2Active READ indicator2Active WRITE setIndicator2Active NOTIFY indicator2ActiveChanged)
    Q_PROPERTY(QString indicator1Icon   READ indicator1Icon   WRITE setIndicator1Icon   NOTIFY indicator1IconChanged)
    Q_PROPERTY(QString indicator2Icon   READ indicator2Icon   WRITE setIndicator2Icon   NOTIFY indicator2IconChanged)

public:
    explicit GaugeItem(QQuickItem *parent = nullptr);
    void paint(QPainter *painter) override;

    double  value()            const { return m_value; }
    double  minValue()         const { return m_minValue; }
    double  maxValue()         const { return m_maxValue; }
    double  step()             const { return m_step; }
    QColor  arcColor()         const { return m_arcColor; }
    double  dangerZone()       const { return m_dangerZone; }
    QString unit()             const { return m_unit; }
    QString centerText()       const { return m_centerText; }
    double  glowIntensity()    const { return m_glowIntensity; }
    bool    dangerBlink()      const { return m_dangerBlink; }
    double  innerArcValue()    const { return m_innerArcValue; }
    double  innerArcMin()      const { return m_innerArcMin; }
    double  innerArcMax()      const { return m_innerArcMax; }
    bool    showInnerArc()     const { return m_showInnerArc; }
    QString innerArcType()     const { return m_innerArcType; }
    bool    indicator1Active() const { return m_indicator1Active; }
    bool    indicator2Active() const { return m_indicator2Active; }
    QString indicator1Icon()   const { return m_indicator1Icon; }
    QString indicator2Icon()   const { return m_indicator2Icon; }

    void setValue(double v);
    void setMinValue(double v)          { m_minValue = v;          emit minValueChanged();         update(); }
    void setMaxValue(double v)          { m_maxValue = v;          emit maxValueChanged();         update(); }
    void setStep(double v)              { m_step = v;              emit stepChanged();             update(); }
    void setArcColor(const QColor &v)   { m_arcColor = v;          emit arcColorChanged();         update(); }
    void setDangerZone(double v)        { m_dangerZone = v;        emit dangerZoneChanged();       update(); }
    void setUnit(const QString &v)      { m_unit = v;              emit unitChanged();             update(); }
    void setCenterText(const QString &v){ m_centerText = v;        emit centerTextChanged();       update(); }
    void setGlowIntensity(double v)     { m_glowIntensity = v;     emit glowIntensityChanged();    update(); }
    void setDangerBlink(bool v)         { m_dangerBlink = v;       emit dangerBlinkChanged();      update(); }
    void setInnerArcValue(double v)     { m_innerArcValue = v;     emit innerArcValueChanged();    update(); }
    void setInnerArcMin(double v)       { m_innerArcMin = v;       emit innerArcMinChanged();      update(); }
    void setInnerArcMax(double v)       { m_innerArcMax = v;       emit innerArcMaxChanged();      update(); }
    void setShowInnerArc(bool v)        { m_showInnerArc = v;      emit showInnerArcChanged();     update(); }
    void setInnerArcType(const QString &v){ m_innerArcType = v;    emit innerArcTypeChanged();     update(); }
    void setIndicator1Active(bool v)    { m_indicator1Active = v;  emit indicator1ActiveChanged(); update(); }
    void setIndicator2Active(bool v)    { m_indicator2Active = v;  emit indicator2ActiveChanged(); update(); }
    void setIndicator1Icon(const QString &v){ m_indicator1Icon = v; emit indicator1IconChanged();  update(); }
    void setIndicator2Icon(const QString &v){ m_indicator2Icon = v; emit indicator2IconChanged();  update(); }

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
    void innerArcValueChanged();
    void innerArcMinChanged();
    void innerArcMaxChanged();
    void showInnerArcChanged();
    void innerArcTypeChanged();
    void indicator1ActiveChanged();
    void indicator2ActiveChanged();
    void indicator1IconChanged();
    void indicator2IconChanged();

private:
    static constexpr double ARC_START = 225.0;
    static constexpr double ARC_SPAN  = -270.0;
    // Внутренняя дуга: нижний сектор циферблата
    // От 130° до 50° (через низ) = 100° дуга
    static constexpr double INNER_ARC_START = 130.0;
    static constexpr double INNER_ARC_SPAN  = -100.0;

    static constexpr auto FONT = "Microgramma";

    double normalize(double v) const;

    void drawBackground      (QPainter *p, QPointF c, double outerR, double innerR);
    void drawOuterRing       (QPainter *p, QPointF c, double outerR);
    void drawArcTrack        (QPainter *p, QPointF c, double outerR, double norm);
    void drawDangerZoneFill  (QPainter *p, QPointF c, double outerR, double norm);
    void drawTicks           (QPainter *p, QPointF c, double outerR, double innerR);
    void drawTickLabels      (QPainter *p, QPointF c, double outerR, double innerR);
    void drawInnerArc        (QPainter *p, QPointF c, double innerR);
    void drawInnerIndicators (QPainter *p, QPointF c, double innerR);
    void drawGlowRing        (QPainter *p, QPointF c, double innerR);
    void drawNeedle          (QPainter *p, QPointF c, double outerR, double innerR, double norm);
    void drawCenterHub       (QPainter *p, QPointF c);
    void drawCenterText      (QPainter *p, QPointF c, double innerR, double norm);

    double  m_value            = 0.0;
    double  m_minValue         = 0.0;
    double  m_maxValue         = 300.0;
    double  m_step             = 20.0;
    QColor  m_arcColor         { "#FF3B30" };
    double  m_dangerZone       = 0.85;
    QString m_unit;
    QString m_centerText;
    double  m_glowIntensity    = 0.0;
    bool    m_dangerBlink      = false;

    double  m_innerArcValue    = 0.0;
    double  m_innerArcMin      = 0.0;
    double  m_innerArcMax      = 100.0;
    bool    m_showInnerArc     = false;
    QString m_innerArcType     = "temp";

    bool    m_indicator1Active = false;
    bool    m_indicator2Active = false;
    QString m_indicator1Icon;
    QString m_indicator2Icon;
};
