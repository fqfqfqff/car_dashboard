#include "Controller.h"
#include <QtMath>

Controller::Controller(QObject *parent) : QObject(parent) {}

// Тестовые методы — просто эмитируют сигнал,
// Simulator/DataModel обновят состояние напрямую
void Controller::testOilPressure()          { emit testIndicator("oilPressure",         true); }
void Controller::testOverheating()          { emit testIndicator("overheating",         true); }
void Controller::testBrakeSystem()          { emit testIndicator("brakeSystem",         true); }
void Controller::testBattery()              { emit testIndicator("batteryFault",        true); }
void Controller::testAirbag()               { emit testIndicator("airbagFault",         true); }
void Controller::testSeatbelt()             { emit testIndicator("seatbelt",            true); }
void Controller::testCheckEngine()          { emit testIndicator("checkEngine",         true); }
void Controller::testAbs()                  { emit testIndicator("absActive",           true); }
void Controller::testEsp()                  { emit testIndicator("espActive",           true); }
void Controller::testTpms()                 { emit testIndicator("tpmsActive",          true); }
void Controller::testFuelLow()              { emit testIndicator("fuelLow",             true); }
void Controller::testBrakeWear()            { emit testIndicator("brakeWear",           true); }
void Controller::testSteeringFault()        { emit testIndicator("steeringFault",       true); }
void Controller::testBrakeFluid()           { emit testIndicator("brakeFluid",          true); }
void Controller::testTransmissionFault()    { emit testIndicator("transmissionFault",   true); }
void Controller::testTransmissionOverheat() { emit testIndicator("transmissionOverheat",true); }
void Controller::testGeneralWarning()       { emit testIndicator("generalWarning",      true); }

void Controller::setGas(float v) {
    m_gas = qBound(0.0f, v, 1.0f);
    emit gasChanged(m_gas);
}
void Controller::setBrake(float v) {
    m_brake = qBound(0.0f, v, 1.0f);
    emit brakeChanged(m_brake);
}
void Controller::setClutch(float v) {
    m_clutch = qBound(0.0f, v, 1.0f);
    emit clutchChanged(m_clutch);
}
void Controller::toggleHandbrake() {
    m_handbrake = !m_handbrake;
    emit handbrakeChanged(m_handbrake);
}
void Controller::setTurnLeft(bool v) {
    if (m_turnLeft == v) return;
    m_turnLeft = v;
    if (v) { m_turnRight = false; emit turnRightChanged(false); }
    emit turnLeftChanged(m_turnLeft);
}
void Controller::setTurnRight(bool v) {
    if (m_turnRight == v) return;
    m_turnRight = v;
    if (v) { m_turnLeft = false; emit turnLeftChanged(false); }
    emit turnRightChanged(m_turnRight);
}
void Controller::setHazard(bool v) {
    m_hazard = v;
    emit hazardChanged(v);
}
void Controller::setLowBeam(bool v) {
    m_lowBeam = v;
    if (v) { m_highBeam = false; emit highBeamChanged(false); }
    emit lowBeamChanged(v);
}
void Controller::setHighBeam(bool v) {
    m_highBeam = v;
    if (v) { m_lowBeam = false; emit lowBeamChanged(false); }
    emit highBeamChanged(v);
}
void Controller::setFogLights(bool v) {
    m_fogLights = v;
    emit fogLightsChanged(v);
}
void Controller::toggleCruise() {
    m_cruise = !m_cruise;
    emit cruiseChanged(m_cruise);
}
void Controller::startEngine() {
    if (m_engineRunning) return;
    m_engineRunning = true;
    emit engineStarted();
}
void Controller::stopEngine() {
    if (!m_engineRunning) return;
    m_engineRunning = false;
    emit engineStopped();
}

