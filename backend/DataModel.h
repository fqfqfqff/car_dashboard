#pragma once
#include <QObject>

class DataModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(double speed      READ speed      WRITE setSpeed      NOTIFY speedChanged)
    Q_PROPERTY(double rpm        READ rpm        WRITE setRpm        NOTIFY rpmChanged)
    Q_PROPERTY(double fuelLevel  READ fuelLevel  WRITE setFuelLevel  NOTIFY fuelLevelChanged)
    Q_PROPERTY(double engineTemp READ engineTemp WRITE setEngineTemp NOTIFY engineTempChanged)

    // Критические
    Q_PROPERTY(bool oilPressure  READ oilPressure  WRITE setOilPressure  NOTIFY oilPressureChanged)
    Q_PROPERTY(bool overheating  READ overheating  WRITE setOverheating  NOTIFY overheatingChanged)
    Q_PROPERTY(bool brakeSystem  READ brakeSystem  WRITE setBrakeSystem  NOTIFY brakeSystemChanged)
    Q_PROPERTY(bool batteryFault READ batteryFault WRITE setBatteryFault NOTIFY batteryFaultChanged)
    Q_PROPERTY(bool airbagFault  READ airbagFault  WRITE setAirbagFault  NOTIFY airbagFaultChanged)
    Q_PROPERTY(bool seatbelt     READ seatbelt     WRITE setSeatbelt     NOTIFY seatbeltChanged)
    Q_PROPERTY(bool brakeFluid        READ brakeFluid        WRITE setBrakeFluid        NOTIFY brakeFluidChanged)
    Q_PROPERTY(bool transmissionFault READ transmissionFault WRITE setTransmissionFault NOTIFY transmissionFaultChanged)
    Q_PROPERTY(bool transmissionOverheat READ transmissionOverheat WRITE setTransmissionOverheat NOTIFY transmissionOverheatChanged)

    // Предупреждения
    Q_PROPERTY(bool checkEngine   READ checkEngine   WRITE setCheckEngine   NOTIFY checkEngineChanged)
    Q_PROPERTY(bool absActive     READ absActive     WRITE setAbsActive     NOTIFY absActiveChanged)
    Q_PROPERTY(bool espActive     READ espActive     WRITE setEspActive     NOTIFY espActiveChanged)
    Q_PROPERTY(bool tpmsActive    READ tpmsActive    WRITE setTpmsActive    NOTIFY tpmsActiveChanged)
    Q_PROPERTY(bool fuelLow       READ fuelLow       WRITE setFuelLow       NOTIFY fuelLowChanged)
    Q_PROPERTY(bool brakeWear     READ brakeWear     WRITE setBrakeWear     NOTIFY brakeWearChanged)
    Q_PROPERTY(bool steeringFault READ steeringFault WRITE setSteeringFault NOTIFY steeringFaultChanged)
    Q_PROPERTY(bool generalWarning READ generalWarning WRITE setGeneralWarning NOTIFY generalWarningChanged)

    // Информационные
    Q_PROPERTY(bool turnLeft     READ turnLeft     WRITE setTurnLeft     NOTIFY turnLeftChanged)
    Q_PROPERTY(bool turnRight    READ turnRight    WRITE setTurnRight    NOTIFY turnRightChanged)
    Q_PROPERTY(bool lowBeam      READ lowBeam      WRITE setLowBeam      NOTIFY lowBeamChanged)
    Q_PROPERTY(bool highBeam     READ highBeam     WRITE setHighBeam     NOTIFY highBeamChanged)
    Q_PROPERTY(bool fogLights    READ fogLights    WRITE setFogLights    NOTIFY fogLightsChanged)
    Q_PROPERTY(bool cruiseActive READ cruiseActive WRITE setCruiseActive NOTIFY cruiseActiveChanged)
    Q_PROPERTY(bool laneAssist   READ laneAssist   WRITE setLaneAssist   NOTIFY laneAssistChanged)
    Q_PROPERTY(bool engineRunning READ engineRunning WRITE setEngineRunning NOTIFY engineRunningChanged)
    Q_PROPERTY(int currentGear READ currentGear WRITE setCurrentGear NOTIFY currentGearChanged)
    Q_PROPERTY(double odometer READ odometer WRITE setOdometer NOTIFY odometerChanged)
    // П.10: перегрев тормозов
    Q_PROPERTY(bool brakeOverheat READ brakeOverheat WRITE setBrakeOverheat NOTIFY brakeOverheatChanged)
    // П.12: CAN-ready — источник данных (симулятор или CAN)
    Q_PROPERTY(bool canConnected  READ canConnected  WRITE setCanConnected  NOTIFY canConnectedChanged)

public:
    explicit DataModel(QObject *parent = nullptr);

    double speed()      const { return m_speed; }
    double rpm()        const { return m_rpm; }
    double fuelLevel()  const { return m_fuelLevel; }
    double engineTemp() const { return m_engineTemp; }
    double odometer() const { return m_odometer; }

    bool brakeOverheat() const { return m_brakeOverheat; }
    bool canConnected()  const { return m_canConnected;  }
    bool oilPressure()   const { return m_oilPressure; }
    bool overheating()   const { return m_overheating; }
    bool brakeSystem()   const { return m_brakeSystem; }
    bool batteryFault()  const { return m_batteryFault; }
    bool airbagFault()   const { return m_airbagFault; }
    bool seatbelt()      const { return m_seatbelt; }
    bool checkEngine()   const { return m_checkEngine; }
    bool absActive()     const { return m_absActive; }
    bool espActive()     const { return m_espActive; }
    bool tpmsActive()    const { return m_tpmsActive; }
    bool fuelLow()       const { return m_fuelLow; }
    bool brakeWear()     const { return m_brakeWear; }
    bool steeringFault() const { return m_steeringFault; }
    bool turnLeft()      const { return m_turnLeft; }
    bool turnRight()     const { return m_turnRight; }
    bool lowBeam()       const { return m_lowBeam; }
    bool highBeam()      const { return m_highBeam; }
    bool fogLights()     const { return m_fogLights; }
    bool cruiseActive()  const { return m_cruiseActive; }
    bool laneAssist()    const { return m_laneAssist; }
    bool engineRunning() const { return m_engineRunning; }
    bool brakeFluid()        const { return m_brakeFluid; }
    bool transmissionFault() const { return m_transmissionFault; }
    bool transmissionOverheat() const { return m_transmissionOverheat; }
    bool generalWarning()    const { return m_generalWarning; }

    int  currentGear() const { return m_currentGear; }
    void setCurrentGear(int v);
    void setSpeed(double v);
    void setRpm(double v);
    void setFuelLevel(double v);
    void setEngineTemp(double v);
    void setEngineRunning(bool v);
    void   setOdometer(double v);
    void setBrakeOverheat(bool v);
    void setCanConnected (bool v);

    void setOilPressure(bool v);
    void setOverheating(bool v);
    void setBrakeSystem(bool v);
    void setBatteryFault(bool v);
    void setAirbagFault(bool v);
    void setSeatbelt(bool v);
    void setCheckEngine(bool v);
    void setAbsActive(bool v);
    void setEspActive(bool v);
    void setTpmsActive(bool v);
    void setFuelLow(bool v);
    void setBrakeWear(bool v);
    void setSteeringFault(bool v);
    void setTurnLeft(bool v);
    void setTurnRight(bool v);
    void setLowBeam(bool v);
    void setHighBeam(bool v);
    void setFogLights(bool v);
    void setCruiseActive(bool v);
    void setLaneAssist(bool v);
    void setBrakeFluid(bool v);
    void setTransmissionFault(bool v);
    void setTransmissionOverheat(bool v);
    void setGeneralWarning(bool v);

signals:
    void speedChanged();
    void rpmChanged();
    void fuelLevelChanged();
    void engineTempChanged();
    void oilPressureChanged();
    void overheatingChanged();
    void brakeSystemChanged();
    void batteryFaultChanged();
    void airbagFaultChanged();
    void seatbeltChanged();
    void checkEngineChanged();
    void absActiveChanged();
    void espActiveChanged();
    void tpmsActiveChanged();
    void fuelLowChanged();
    void brakeWearChanged();
    void steeringFaultChanged();
    void turnLeftChanged();
    void turnRightChanged();
    void lowBeamChanged();
    void highBeamChanged();
    void fogLightsChanged();
    void cruiseActiveChanged();
    void laneAssistChanged();
    void engineRunningChanged();
    void currentGearChanged();
    void odometerChanged();
    void brakeOverheatChanged();
    void canConnectedChanged();
    void brakeFluidChanged();
    void transmissionFaultChanged();
    void transmissionOverheatChanged();
    void generalWarningChanged();

private:
    double m_speed      = 0.0;
    double m_rpm        = 0.0;
    double m_fuelLevel  = 75.0;
    double m_engineTemp = 20.0;
    double m_odometer = 100.0; // начальное значение 100 км

    int m_currentGear = 0;

    bool m_brakeOverheat = false;
    bool m_canConnected  = false;
    bool m_oilPressure   = false;
    bool m_overheating   = false;
    bool m_brakeSystem   = false;
    bool m_batteryFault  = false;
    bool m_airbagFault   = false;
    bool m_seatbelt      = true;
    bool m_checkEngine   = false;
    bool m_absActive     = false;
    bool m_espActive     = false;
    bool m_tpmsActive    = false;
    bool m_fuelLow       = false;
    bool m_brakeWear     = false;
    bool m_steeringFault = false;
    bool m_turnLeft      = false;
    bool m_turnRight     = false;
    bool m_lowBeam       = false;
    bool m_highBeam      = false;
    bool m_fogLights     = false;
    bool m_cruiseActive  = false;
    bool m_laneAssist    = false;
    bool m_engineRunning = false;
    bool m_brakeFluid = false;
    bool m_transmissionFault = false;
    bool m_transmissionOverheat = false;
    bool m_generalWarning = false;
};
