#include "DataModel.h"

DataModel::DataModel(QObject *parent) : QObject(parent) {}

void DataModel::setSpeed(double v) {
    v = qBound(0.0, v, 300.0);
    if (qFuzzyCompare(m_speed, v)) return;
    m_speed = v;
    emit speedChanged();
}

void DataModel::setRpm(double v) {
    v = qBound(0.0, v, 8000.0);
    if (qFuzzyCompare(m_rpm, v)) return;
    m_rpm = v;
    emit rpmChanged();
}

void DataModel::setFuelLevel(double v) {
    v = qBound(0.0, v, 100.0);
    if (qFuzzyCompare(m_fuelLevel, v)) return;
    m_fuelLevel = v;
    emit fuelLevelChanged();
    setFuelLow(v < 10.0);
}

void DataModel::setEngineTemp(double v) {
    v = qBound(0.0, v, 130.0);
    if (qFuzzyCompare(m_engineTemp, v)) return;
    m_engineTemp = v;
    emit engineTempChanged();
    setOverheating(v > 108.0);
}

void DataModel::setBatteryVoltage(double v)
{
    v = qBound(0.0, v, 32.0);
    if (qFuzzyCompare(m_batteryVoltage, v)) return;
    m_batteryVoltage = v;
    emit batteryVoltageChanged();

    if (v > 0.0) {
        setBatteryFault(v < 11.4 || v > 15.2);
    }
}

void DataModel::setEngineLoad(double v)
{
    v = qBound(0.0, v, 100.0);
    if (qFuzzyCompare(m_engineLoad, v)) return;
    m_engineLoad = v;
    emit engineLoadChanged();
}

#define BOOL_SETTER(Name, member, Signal) \
void DataModel::set##Name(bool v) { \
        if (m_##member == v) return; \
        m_##member = v; \
        emit Signal##Changed(); \
}

void DataModel::setCurrentGear(int v) {
    if (m_currentGear == v) return;
    m_currentGear = v;
    emit currentGearChanged();
}

void DataModel::setOdometer(double v)
{
    if (qFuzzyCompare(m_odometer, v)) return;
    m_odometer = v;
    emit odometerChanged();
}

void DataModel::setBrakeOverheat(bool v)
{
    if (m_brakeOverheat == v) return;
    m_brakeOverheat = v;
    emit brakeOverheatChanged();
}

void DataModel::setCanConnected(bool v)
{
    if (m_canConnected == v) return;
    m_canConnected = v;
    emit canConnectedChanged();
}

BOOL_SETTER(OilPressure,   oilPressure,   oilPressure)
BOOL_SETTER(Overheating,   overheating,   overheating)
BOOL_SETTER(BrakeSystem,   brakeSystem,   brakeSystem)
BOOL_SETTER(BatteryFault,  batteryFault,  batteryFault)
BOOL_SETTER(AirbagFault,   airbagFault,   airbagFault)
BOOL_SETTER(Seatbelt,      seatbelt,      seatbelt)
BOOL_SETTER(CheckEngine,   checkEngine,   checkEngine)
BOOL_SETTER(AbsActive,     absActive,     absActive)
BOOL_SETTER(EspActive,     espActive,     espActive)
BOOL_SETTER(TpmsActive,    tpmsActive,    tpmsActive)
BOOL_SETTER(FuelLow,       fuelLow,       fuelLow)
BOOL_SETTER(BrakeWear,     brakeWear,     brakeWear)
BOOL_SETTER(SteeringFault, steeringFault, steeringFault)
BOOL_SETTER(TurnLeft,      turnLeft,      turnLeft)
BOOL_SETTER(TurnRight,     turnRight,     turnRight)
BOOL_SETTER(LowBeam,       lowBeam,       lowBeam)
BOOL_SETTER(HighBeam,      highBeam,      highBeam)
BOOL_SETTER(FogLights,     fogLights,     fogLights)
BOOL_SETTER(CruiseActive,  cruiseActive,  cruiseActive)
BOOL_SETTER(EngineRunning, engineRunning, engineRunning)
BOOL_SETTER(BrakeFluid,        brakeFluid,        brakeFluid)
BOOL_SETTER(TransmissionFault, transmissionFault, transmissionFault)
BOOL_SETTER(TransmissionOverheat, transmissionOverheat, transmissionOverheat)
BOOL_SETTER(GeneralWarning,    generalWarning,    generalWarning)
