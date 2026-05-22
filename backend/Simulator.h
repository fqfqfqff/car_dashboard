#pragma once

#include <QObject>
#include <QTimer>
#include "DataModel.h"
#include "Controller.h"

class Simulator : public QObject
{
    Q_OBJECT

    Q_PROPERTY(double fuelL100   READ fuelL100   NOTIFY fuelChanged)
    Q_PROPERTY(double fuelLph    READ fuelLph    NOTIFY fuelChanged)
    Q_PROPERTY(double fuelAvg    READ fuelAvg    NOTIFY fuelChanged)
    // П.3: целевая скорость круиз-контроля для отображения в QML
    Q_PROPERTY(double cruiseTarget READ cruiseTarget NOTIFY cruiseChanged)
    // П.9: флаг пробуксовки для QML (мигание ESP)
    Q_PROPERTY(bool   wheelSpin  READ wheelSpin  NOTIFY wheelSpinChanged)

public:
    explicit Simulator(DataModel *model, Controller *controller, QObject *parent = nullptr);
    void start();

    double fuelL100()     const { return m_fuelL100;     }
    double fuelLph()      const { return m_fuelLph;      }
    double fuelAvg()      const { return m_fuelAvg;      }
    double cruiseTarget() const { return m_cruiseTarget; }
    bool   wheelSpin()    const { return m_wheelSpin;    }

signals:
    void fuelChanged();
    void cruiseChanged();
    void wheelSpinChanged();

private slots:
    void tick();

private:
    void updateGear();
    void updateFuel      (double dt, double kmh);
    void updateEngineTemp(double dt, double kmh);
    void updateOdometer  (double dt, double kmh);
    // П.3: PID регулятор круиз-контроля
    void updateCruise    (double dt, double kmh);

    static double lerp(double a, double b, double t) { return a + (b - a) * t; }

    DataModel  *m_model;
    Controller *m_controller;
    QTimer      m_timer;

    bool   m_engineOn    = false;
    bool   m_gasHeld     = false;
    bool   m_brakeHeld   = false;
    float  m_gasLevel    = 0.0f;
    float  m_brakeLevel  = 0.0f;
    int    m_tick        = 0;
    int    m_gear        = 0;
    double m_speedMs     = 0.0;
    double m_rpm         = 0.0;
    double m_rpmTarget   = 0.0;

    // П.8: турбо-лаг — задержка нарастания оборотов при резком газе
    double m_turboBoost      = 0.0;   // текущий буст 0.0–1.0
    double m_turboPressure   = 0.0;   // давление наддува (накапливается)
    double m_prevGasLevel    = 0.0;   // предыдущее положение педали

    // П.3: PID круиз-контроль
    bool   m_cruiseActive    = false;
    double m_cruiseTarget    = 0.0;   // целевая скорость км/ч
    double m_pidIntegral     = 0.0;   // накопленная ошибка
    double m_pidPrevError    = 0.0;   // предыдущая ошибка

    // П.9: пробуксовка
    bool   m_wheelSpin       = false;
    double m_wheelSpinTimer  = 0.0;

    // Расход
    double m_fuelL100        = -1.0;
    double m_fuelLph         =  0.0;
    double m_fuelAvg         =  0.0;
    double m_totalFuelBurned =  0.0;
    double m_totalDistKm     =  0.0;
};
