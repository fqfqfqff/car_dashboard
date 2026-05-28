#include "Simulator.h"
#include <QtMath>

// ── Физика автомобиля ─────────────────────────────────────────────────────────
static constexpr double MASS        = 1550.0;
static constexpr double MAX_POWER_W = 477522.0;  // 650 л.с.
static constexpr double CDA         = 0.68;
static constexpr double RHO         = 1.225;
static constexpr double CR          = 0.013;
static constexpr double G           = 9.81;
static constexpr double FUEL_TANK_L = 55.0;
static constexpr double WHEEL_R     = 0.318;

static constexpr double GEAR_RATIO[7] = { 0.0, 14.8, 8.60, 5.60, 4.10, 3.20, 2.60 };
static constexpr double UP_KMH[7]     = { 0,   45,   85,  130,  175,  225,  999 };
static constexpr double DOWN_KMH[7]   = { 0,    0,   30,   65,  105,  155,  195 };

// Кривая момента 650 л.с. с турбо
static double torqueNm(double rpm)
{
    if (rpm < 800)   return 0.0;
    if (rpm < 1400)  return 120.0 * (rpm - 800) / 600.0;
    if (rpm < 3000)  return 120.0 + 700.0 * (rpm - 1400) / 1600.0;
    if (rpm < 4500)  return 820.0;
    if (rpm < 6000)  return 820.0 - 200.0 * (rpm - 4500) / 1500.0;
    if (rpm < 7200)  return 620.0 - 400.0 * (rpm - 6000) / 1200.0;
    return 100.0;
}

static double rpmForSpeed(double speedMs, int gear)
{
    if (gear <= 0 || speedMs < 0.1) return 850.0;
    return qBound(850.0,
                  (speedMs / WHEEL_R) * GEAR_RATIO[gear] * 60.0 / (2.0 * M_PI),
                  7500.0);
}

Simulator::Simulator(DataModel *model, Controller *controller, QObject *parent)
    : QObject(parent), m_model(model), m_controller(controller)
{
    connect(controller, &Controller::engineStarted, this, [this]() {
        m_engineOn       = true;
        m_tick           = 0;
        m_gear           = 0;
        m_speedMs        = 0.0;
        m_rpm            = 850.0;
        m_rpmTarget      = 850.0;
        m_turboBoost     = 0.0;
        m_turboPressure  = 0.0;
        m_prevGasLevel   = 0.0;
        m_pidIntegral    = 0.0;
        m_pidPrevError   = 0.0;
        m_fuelAvg        = 0.0;
        m_totalFuelBurned = 0.0;
        m_totalDistKm    = 0.0;
        m_model->setEngineRunning(true);
    });

    connect(controller, &Controller::engineStopped, this, [this]() {
        m_engineOn     = false;
        m_gasHeld      = false;
        m_brakeHeld    = false;
        m_gear         = 0;
        m_cruiseActive = false;
        m_wheelSpin    = false;
        emit wheelSpinChanged();
        // Удержание в полосе отключается вместе с двигателем
        m_model->setLaneAssist(false);
    });

    connect(controller, &Controller::gasChanged, this, [this](float v) {
        m_prevGasLevel = m_gasLevel;
        m_gasLevel     = qBound(0.0f, v, 1.0f);
        m_gasHeld      = (v > 0.01f);
        // При нажатии газа деактивируем круиз-контроль
        if (m_gasHeld && m_cruiseActive) {
            m_cruiseActive = false;
            m_model->setCruiseActive(false);
            emit cruiseChanged();
        }
    });

    connect(controller, &Controller::brakeChanged, this, [this](float v) {
        m_brakeLevel = qBound(0.0f, v, 1.0f);
        m_brakeHeld  = (v > 0.01f);
        // Тормоз тоже деактивирует круиз
        if (m_brakeHeld && m_cruiseActive) {
            m_cruiseActive = false;
            m_model->setCruiseActive(false);
            emit cruiseChanged();
        }
    });

    // П.3: включение/выключение круиз-контроля
    connect(controller, &Controller::cruiseChanged, this, [this](bool v) {
        m_cruiseActive = v && m_engineOn;
        if (m_cruiseActive) {
            // Запоминаем текущую скорость как целевую
            m_cruiseTarget   = m_model->speed();
            m_pidIntegral    = 0.0;
            m_pidPrevError   = 0.0;
        }
        m_model->setCruiseActive(m_cruiseActive);
        emit cruiseChanged();
    });

    // Удержание в полосе — включается только при работающем двигателе
    connect(controller, &Controller::laneAssistChanged, this, [this](bool v) {
        m_model->setLaneAssist(v && m_engineOn);
    });

    connect(controller, &Controller::turnLeftChanged,  m_model, &DataModel::setTurnLeft);
    connect(controller, &Controller::turnRightChanged, m_model, &DataModel::setTurnRight);
    connect(controller, &Controller::hazardChanged, this, [this](bool v) {
        m_model->setTurnLeft(v);
        m_model->setTurnRight(v);
    });
    connect(controller, &Controller::lowBeamChanged,   m_model, &DataModel::setLowBeam);
    connect(controller, &Controller::highBeamChanged,  m_model, &DataModel::setHighBeam);
    connect(controller, &Controller::fogLightsChanged, m_model, &DataModel::setFogLights);
    connect(controller, &Controller::handbrakeChanged, m_model, &DataModel::setBrakeSystem);

    connect(controller, &Controller::testIndicator, this, [this](const QString &name, bool) {
        if      (name == "oilPressure")   m_model->setOilPressure   (!m_model->oilPressure());
        else if (name == "overheating")   m_model->setOverheating   (!m_model->overheating());
        else if (name == "brakeSystem")   m_model->setBrakeSystem   (!m_model->brakeSystem());
        else if (name == "batteryFault")  m_model->setBatteryFault  (!m_model->batteryFault());
        else if (name == "airbagFault")   m_model->setAirbagFault   (!m_model->airbagFault());
        else if (name == "seatbelt")      m_model->setSeatbelt      (!m_model->seatbelt());
        else if (name == "checkEngine")   m_model->setCheckEngine   (!m_model->checkEngine());
        else if (name == "absActive")     m_model->setAbsActive     (!m_model->absActive());
        else if (name == "espActive")     m_model->setEspActive     (!m_model->espActive());
        else if (name == "tpmsActive")    m_model->setTpmsActive    (!m_model->tpmsActive());
        else if (name == "fuelLow")       m_model->setFuelLow       (!m_model->fuelLow());
        else if (name == "brakeWear")     m_model->setBrakeWear     (!m_model->brakeWear());
        else if (name == "steeringFault")        m_model->setSteeringFault       (!m_model->steeringFault());
        else if (name == "brakeFluid")            m_model->setBrakeFluid          (!m_model->brakeFluid());
        else if (name == "transmissionFault")     m_model->setTransmissionFault   (!m_model->transmissionFault());
        else if (name == "transmissionOverheat")  m_model->setTransmissionOverheat(!m_model->transmissionOverheat());
        else if (name == "generalWarning")        m_model->setGeneralWarning      (!m_model->generalWarning());
    });
}

void Simulator::start()
{
    connect(&m_timer, &QTimer::timeout, this, &Simulator::tick);
    m_timer.setInterval(33);
    m_timer.start();
}

void Simulator::updateGear()
{
    if (!m_engineOn || m_speedMs < 0.5) { m_gear = 0; return; }
    const double kmh = m_speedMs * 3.6;
    if (m_gear < 6 && kmh >= UP_KMH[m_gear])   { m_gear++; m_rpm *= 0.68; }
    if (m_gear > 1 && kmh < DOWN_KMH[m_gear])  { m_gear--; m_rpm *= 1.22; }
    m_gear = qBound(1, m_gear, 6);
}

void Simulator::tick()
{
    // Если данные идут с реального CAN — симулятор не трогает модель
    if (m_model->canConnected()) return;

    m_tick++;
    const double dt = 0.033;

    if (!m_engineOn) {
        m_speedMs = qMax(0.0, m_speedMs - 1.5 * dt);
        m_rpm     = lerp(m_rpm, 0.0, 0.06);
        m_model->setEngineTemp(lerp(m_model->engineTemp(), 20.0, 0.002));
        m_model->setSpeed(m_speedMs * 3.6);
        m_model->setRpm(m_rpm < 30.0 ? 0.0 : m_rpm);
        if (m_rpm < 30.0) m_model->setEngineRunning(false);
        return;
    }

    updateGear();
    const int activeGear = qMax(1, m_gear);

    // П.3: PID круиз-контроль управляет газом
    double effectiveGas = m_gasLevel;
    if (m_cruiseActive && !m_brakeHeld && !m_gasHeld) {
        updateCruise(dt, m_speedMs * 3.6);
        effectiveGas = qBound(0.0, m_pidIntegral, 1.0); // PID выход
    }

    // П.8: турбо-лаг
    // Турбина раскручивается при нажатии газа с задержкой ~0.4 сек
    const double gasChange = effectiveGas - m_prevGasLevel;
    if (gasChange > 0.05) {
        // Резкое нажатие газа — давление наддува нарастает медленно
        m_turboPressure = lerp(m_turboPressure, effectiveGas, 0.08);
    } else {
        // Отпускание газа — турбина быстро сбрасывает давление
        m_turboPressure = lerp(m_turboPressure, effectiveGas, 0.25);
    }
    m_turboBoost = m_turboPressure;
    m_prevGasLevel = effectiveGas;

    // Эффективный газ с турбо-лагом (на низких оборотах турбина не даёт полный буст)
    const double turboEff    = qBound(0.0, (m_rpm - 1500.0) / 2000.0, 1.0);
    const double gasWithTurbo = effectiveGas * (0.4 + 0.6 * turboEff * m_turboBoost
                                                + 0.6 * (1.0 - turboEff) * effectiveGas);

    // ── Силы ──────────────────────────────────────────────────────────────────
    double accel = 0.0;
    const double f_aero = 0.5 * RHO * CDA * m_speedMs * m_speedMs;
    const double f_roll = CR * MASS * G;

    if ((m_gasHeld || m_cruiseActive) && !m_brakeHeld) {
        const double efficiency = 0.92;
        const double torque     = torqueNm(m_rpm) * gasWithTurbo;
        const double wheelForce = torque * GEAR_RATIO[activeGear] * efficiency / WHEEL_R;
        accel = (wheelForce - f_aero - f_roll) / MASS;

        // П.9: пробуксовка на старте
        // При большом газе на 1-й передаче и малой скорости — тяга ограничивается
        const double kmhNow = m_speedMs * 3.6;
        if (activeGear == 1 && gasWithTurbo > 0.7 && kmhNow < 40.0) {
            const double spinThreshold = 6.0 * gasWithTurbo;
            if (accel > spinThreshold) {
                // Пробуксовка! ESP ограничивает тягу
                accel = spinThreshold * 0.65;
                if (!m_wheelSpin) {
                    m_wheelSpin = true;
                    m_wheelSpinTimer = 0.0;
                    m_model->setEspActive(true);
                    emit wheelSpinChanged();
                }
            }
        }

        if (kmhNow > 270.0) accel *= qMax(0.0, (300.0 - kmhNow) / 30.0);

    } else if (m_brakeHeld) {
        accel = qMax(-(m_brakeLevel * MASS * G * 0.88 / MASS), -12.0);

        // П.10: перегрев тормозов
        // При длительном интенсивном торможении тормоза перегреваются
        m_model->setBrakeWear(m_brakeLevel > 0.7 && m_speedMs > 20.0
                                      && m_tick % 300 == 0
                                  ? !m_model->brakeWear()
                                  : m_model->brakeWear());

    } else {
        accel = -(f_aero + f_roll) / MASS;
        if (m_speedMs < 3.0) accel = qMax(accel, -1.2);
    }

    // П.9: снимаем пробуксовку через 1.5 сек
    if (m_wheelSpin) {
        m_wheelSpinTimer += dt;
        if (m_wheelSpinTimer > 1.5 || m_speedMs * 3.6 > 40.0) {
            m_wheelSpin = false;
            m_model->setEspActive(false);
            emit wheelSpinChanged();
        }
    }

    m_speedMs = qBound(0.0, m_speedMs + accel * dt, 83.3);
    const double kmh = m_speedMs * 3.6;

    // ── Обороты с инерцией + турбо-лаг ───────────────────────────────────────
    const double rpmKinematic = rpmForSpeed(m_speedMs, activeGear);

    if ((m_gasHeld || m_cruiseActive) && !m_brakeHeld) {
        // Турбо-лаг влияет на скорость нарастания оборотов
        const double rpmGasTarget = qMin(rpmKinematic * 1.08 + gasWithTurbo * 500.0, 7200.0);
        m_rpmTarget = rpmGasTarget;
        // При турбо-лаге обороты нарастают медленнее (0.12 вместо 0.20)
        const double alpha = m_turboBoost < 0.5
                                 ? lerp(0.08, 0.20, m_turboBoost * 2.0)
                                 : 0.20;
        m_rpm = lerp(m_rpm, m_rpmTarget, (m_rpmTarget > m_rpm) ? alpha : 0.10);

    } else if (m_brakeHeld) {
        m_rpmTarget = qMax(rpmKinematic * 0.95, 850.0);
        m_rpm       = lerp(m_rpm, m_rpmTarget, 0.12);
    } else {
        m_rpmTarget = qMax(rpmKinematic, 850.0);
        const double alpha = (m_rpmTarget > m_rpm) ? 0.08 : 0.05;
        m_rpm = lerp(m_rpm, m_rpmTarget, alpha);
    }

    if (m_rpm > 7200.0) m_rpm = lerp(m_rpm, 7000.0, 0.35);
    if (m_speedMs < 0.3 && !m_gasHeld) m_rpm = lerp(m_rpm, 850.0, 0.08);

    m_model->setSpeed(kmh);
    m_model->setRpm(qBound(0.0, m_rpm, 8000.0));
    m_model->setCurrentGear(m_gear);

    updateFuel      (dt, kmh);
    updateEngineTemp(dt, kmh);
    updateOdometer  (dt, kmh);

    if (m_tick == 1)  m_model->setSeatbelt(true);
    if (m_tick == 90) m_model->setSeatbelt(false);
}

// ─────────────────────────────────────────────────────────────────────────────
// П.3: PID круиз-контроль
// Классический PID: error = target - current
// output = Kp*e + Ki*integral + Kd*derivative
// ─────────────────────────────────────────────────────────────────────────────
void Simulator::updateCruise(double dt, double kmh)
{
    const double Kp = 0.040;  // пропорциональный коэффициент
    const double Ki = 0.008;  // интегральный (устраняет статическую ошибку)
    const double Kd = 0.012;  // дифференциальный (гасит колебания)

    const double error      = m_cruiseTarget - kmh;
    m_pidIntegral          += error * dt;
    m_pidIntegral           = qBound(-30.0, m_pidIntegral, 30.0); // anti-windup
    const double derivative = (error - m_pidPrevError) / dt;
    m_pidPrevError          = error;

    // PID выход — положение виртуальной педали газа 0.0–1.0
    const double output = Kp * error + Ki * m_pidIntegral + Kd * derivative;
    m_pidIntegral = qBound(0.0, output, 1.0); // используем как эффективный газ
}

void Simulator::updateFuel(double dt, double kmh)
{
    if (!m_engineOn) { emit fuelChanged(); return; }

    const double omega        = m_rpm * 2.0 * M_PI / 60.0;
    const double engineTorque = torqueNm(m_rpm) * qMax((double)m_gasLevel, 0.04);
    const double enginePower  = engineTorque * omega;

    double bsfc;
    if      (m_rpm < 1200) bsfc = 460.0;
    else if (m_rpm < 2000) bsfc = 320.0 - (m_rpm - 1200) / 800.0  * 55.0;
    else if (m_rpm < 3000) bsfc = 265.0 - (m_rpm - 2000) / 1000.0 * 20.0;
    else if (m_rpm < 4500) bsfc = 245.0;
    else if (m_rpm < 6000) bsfc = 245.0 + (m_rpm - 4500) / 1500.0 * 60.0;
    else                   bsfc = 305.0 + (m_rpm - 6000) / 1500.0 * 85.0;

    double litersBurned = 0.0;

    if (kmh < 2.0) {
        const double idlePowerW = 2200.0 + (m_rpm - 850.0) * 0.4;
        litersBurned = (bsfc * idlePowerW / 1000.0) / 3600.0 / 745.0 * dt;
        m_fuelLph    = litersBurned / dt * 3600.0;
        m_fuelL100   = -1.0;
    } else if (!m_gasHeld && !m_cruiseActive && m_rpm > 1100.0 && kmh > 25.0) {
        litersBurned = 0.0;
        m_fuelL100   = 0.0;
        m_fuelLph    = 0.0;
    } else {
        const double powerKw  = qMax(enginePower, 500.0) / 1000.0;
        const double lps      = (bsfc * powerKw) / 3600.0 / 745.0;
        litersBurned          = lps * dt;
        const double lph      = lps * 3600.0;
        m_fuelL100 = (kmh > 1.0) ? qBound(3.0, (lph / kmh) * 100.0, 45.0) : 0.0;
        m_fuelLph  = 0.0;
    }

    m_model->setFuelLevel(qMax(0.0,
                               m_model->fuelLevel() - (litersBurned / FUEL_TANK_L * 100.0)));

    if (kmh >= 2.0) {
        const double distKm = (kmh / 3600.0) * dt;
        m_totalDistKm     += distKm;
        m_totalFuelBurned += litersBurned;
        if (m_totalDistKm > 0.1)
            m_fuelAvg = qBound(3.0, (m_totalFuelBurned / m_totalDistKm) * 100.0, 45.0);
    }

    emit fuelChanged();
}

void Simulator::updateEngineTemp(double /*dt*/, double kmh)
{
    const double rpmLoad = qBound(0.0, (m_rpm - 850.0) / 6500.0, 1.0);
    double tTarget = (!m_gasHeld && kmh < 5.0)
                         ? 88.0
                         : 88.0 + rpmLoad * 24.0;
    if (kmh > 40.0) tTarget -= (kmh - 40.0) * 0.050;
    tTarget = qBound(20.0, tTarget, 115.0);

    const double tempDiff = tTarget - m_model->engineTemp();
    const double alpha    = (tempDiff > 0)
                             ? (m_model->engineTemp() < 60.0 ? 0.008 : 0.004)
                             : 0.002;
    m_model->setEngineTemp(qBound(20.0, m_model->engineTemp() + tempDiff * alpha, 115.0));
    m_model->setOverheating(m_model->engineTemp() > 108.0);
}

void Simulator::updateOdometer(double dt, double kmh)
{
    if (kmh < 0.5) return;
    m_model->setOdometer(m_model->odometer() + (kmh / 3600.0) * dt);
}
