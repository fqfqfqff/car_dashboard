#pragma once
#include <QObject>

class Controller : public QObject
{
    Q_OBJECT

public:
    explicit Controller(QObject *parent = nullptr);

    float gasLevel()    const { return m_gas; }
    float brakeLevel()  const { return m_brake; }
    float clutchLevel() const { return m_clutch; }
    bool  handbrake()   const { return m_handbrake; }
    bool engineRunning() const { return m_engineRunning; }

public slots:
    Q_INVOKABLE void setGas(float v);
    Q_INVOKABLE void setBrake(float v);
    Q_INVOKABLE void setClutch(float v);
    Q_INVOKABLE void toggleHandbrake();
    Q_INVOKABLE void setTurnLeft(bool v);
    Q_INVOKABLE void setTurnRight(bool v);
    Q_INVOKABLE void setHazard(bool v);
    Q_INVOKABLE void setLowBeam(bool v);
    Q_INVOKABLE void setHighBeam(bool v);
    Q_INVOKABLE void setFogLights(bool v);
    Q_INVOKABLE void toggleCruise();
    Q_INVOKABLE void startEngine();
    Q_INVOKABLE void stopEngine();
    Q_INVOKABLE void testOilPressure();
    Q_INVOKABLE void testOverheating();
    Q_INVOKABLE void testBrakeSystem();
    Q_INVOKABLE void testBattery();
    Q_INVOKABLE void testAirbag();
    Q_INVOKABLE void testSeatbelt();
    Q_INVOKABLE void testCheckEngine();
    Q_INVOKABLE void testAbs();
    Q_INVOKABLE void testEsp();
    Q_INVOKABLE void testTpms();
    Q_INVOKABLE void testFuelLow();
    Q_INVOKABLE void testBrakeWear();
    Q_INVOKABLE void testSteeringFault();
    Q_INVOKABLE void testBrakeFluid();
    Q_INVOKABLE void testTransmissionFault();
    Q_INVOKABLE void testTransmissionOverheat();
    Q_INVOKABLE void testGeneralWarning();

signals:
    void gasChanged(float v);
    void brakeChanged(float v);
    void clutchChanged(float v);
    void handbrakeChanged(bool v);
    void turnLeftChanged(bool v);
    void turnRightChanged(bool v);
    void hazardChanged(bool v);
    void lowBeamChanged(bool v);
    void highBeamChanged(bool v);
    void fogLightsChanged(bool v);
    void cruiseChanged(bool v);
    void engineStarted();
    void engineStopped();
    void testIndicator(const QString &name, bool value);

private:
    float m_gas     = 0.0f;
    float m_brake   = 0.0f;
    float m_clutch  = 0.0f;
    bool  m_handbrake  = false;
    bool  m_turnLeft   = false;
    bool  m_turnRight  = false;
    bool  m_hazard     = false;
    bool  m_lowBeam    = false;
    bool  m_highBeam   = false;
    bool  m_fogLights  = false;
    bool  m_cruise     = false;
    bool m_engineRunning = false;
};
