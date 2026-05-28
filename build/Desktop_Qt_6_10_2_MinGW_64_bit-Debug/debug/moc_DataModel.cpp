/****************************************************************************
** Meta object code from reading C++ file 'DataModel.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../backend/DataModel.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'DataModel.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.10.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN9DataModelE_t {};
} // unnamed namespace

template <> constexpr inline auto DataModel::qt_create_metaobjectdata<qt_meta_tag_ZN9DataModelE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "DataModel",
        "speedChanged",
        "",
        "rpmChanged",
        "fuelLevelChanged",
        "engineTempChanged",
        "oilPressureChanged",
        "overheatingChanged",
        "brakeSystemChanged",
        "batteryFaultChanged",
        "airbagFaultChanged",
        "seatbeltChanged",
        "checkEngineChanged",
        "absActiveChanged",
        "espActiveChanged",
        "tpmsActiveChanged",
        "fuelLowChanged",
        "brakeWearChanged",
        "steeringFaultChanged",
        "turnLeftChanged",
        "turnRightChanged",
        "lowBeamChanged",
        "highBeamChanged",
        "fogLightsChanged",
        "cruiseActiveChanged",
        "laneAssistChanged",
        "engineRunningChanged",
        "currentGearChanged",
        "odometerChanged",
        "brakeOverheatChanged",
        "canConnectedChanged",
        "brakeFluidChanged",
        "transmissionFaultChanged",
        "transmissionOverheatChanged",
        "generalWarningChanged",
        "speed",
        "rpm",
        "fuelLevel",
        "engineTemp",
        "oilPressure",
        "overheating",
        "brakeSystem",
        "batteryFault",
        "airbagFault",
        "seatbelt",
        "brakeFluid",
        "transmissionFault",
        "transmissionOverheat",
        "checkEngine",
        "absActive",
        "espActive",
        "tpmsActive",
        "fuelLow",
        "brakeWear",
        "steeringFault",
        "generalWarning",
        "turnLeft",
        "turnRight",
        "lowBeam",
        "highBeam",
        "fogLights",
        "cruiseActive",
        "laneAssist",
        "engineRunning",
        "currentGear",
        "odometer",
        "brakeOverheat",
        "canConnected"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'speedChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'rpmChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'fuelLevelChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'engineTempChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'oilPressureChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'overheatingChanged'
        QtMocHelpers::SignalData<void()>(7, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brakeSystemChanged'
        QtMocHelpers::SignalData<void()>(8, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'batteryFaultChanged'
        QtMocHelpers::SignalData<void()>(9, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'airbagFaultChanged'
        QtMocHelpers::SignalData<void()>(10, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'seatbeltChanged'
        QtMocHelpers::SignalData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'checkEngineChanged'
        QtMocHelpers::SignalData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'absActiveChanged'
        QtMocHelpers::SignalData<void()>(13, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'espActiveChanged'
        QtMocHelpers::SignalData<void()>(14, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'tpmsActiveChanged'
        QtMocHelpers::SignalData<void()>(15, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'fuelLowChanged'
        QtMocHelpers::SignalData<void()>(16, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brakeWearChanged'
        QtMocHelpers::SignalData<void()>(17, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'steeringFaultChanged'
        QtMocHelpers::SignalData<void()>(18, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'turnLeftChanged'
        QtMocHelpers::SignalData<void()>(19, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'turnRightChanged'
        QtMocHelpers::SignalData<void()>(20, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'lowBeamChanged'
        QtMocHelpers::SignalData<void()>(21, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'highBeamChanged'
        QtMocHelpers::SignalData<void()>(22, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'fogLightsChanged'
        QtMocHelpers::SignalData<void()>(23, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cruiseActiveChanged'
        QtMocHelpers::SignalData<void()>(24, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'laneAssistChanged'
        QtMocHelpers::SignalData<void()>(25, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'engineRunningChanged'
        QtMocHelpers::SignalData<void()>(26, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentGearChanged'
        QtMocHelpers::SignalData<void()>(27, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'odometerChanged'
        QtMocHelpers::SignalData<void()>(28, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brakeOverheatChanged'
        QtMocHelpers::SignalData<void()>(29, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'canConnectedChanged'
        QtMocHelpers::SignalData<void()>(30, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brakeFluidChanged'
        QtMocHelpers::SignalData<void()>(31, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'transmissionFaultChanged'
        QtMocHelpers::SignalData<void()>(32, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'transmissionOverheatChanged'
        QtMocHelpers::SignalData<void()>(33, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'generalWarningChanged'
        QtMocHelpers::SignalData<void()>(34, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'speed'
        QtMocHelpers::PropertyData<double>(35, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'rpm'
        QtMocHelpers::PropertyData<double>(36, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'fuelLevel'
        QtMocHelpers::PropertyData<double>(37, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'engineTemp'
        QtMocHelpers::PropertyData<double>(38, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'oilPressure'
        QtMocHelpers::PropertyData<bool>(39, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'overheating'
        QtMocHelpers::PropertyData<bool>(40, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'brakeSystem'
        QtMocHelpers::PropertyData<bool>(41, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'batteryFault'
        QtMocHelpers::PropertyData<bool>(42, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
        // property 'airbagFault'
        QtMocHelpers::PropertyData<bool>(43, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 8),
        // property 'seatbelt'
        QtMocHelpers::PropertyData<bool>(44, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 9),
        // property 'brakeFluid'
        QtMocHelpers::PropertyData<bool>(45, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 29),
        // property 'transmissionFault'
        QtMocHelpers::PropertyData<bool>(46, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 30),
        // property 'transmissionOverheat'
        QtMocHelpers::PropertyData<bool>(47, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 31),
        // property 'checkEngine'
        QtMocHelpers::PropertyData<bool>(48, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 10),
        // property 'absActive'
        QtMocHelpers::PropertyData<bool>(49, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 11),
        // property 'espActive'
        QtMocHelpers::PropertyData<bool>(50, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'tpmsActive'
        QtMocHelpers::PropertyData<bool>(51, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 13),
        // property 'fuelLow'
        QtMocHelpers::PropertyData<bool>(52, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 14),
        // property 'brakeWear'
        QtMocHelpers::PropertyData<bool>(53, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 15),
        // property 'steeringFault'
        QtMocHelpers::PropertyData<bool>(54, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 16),
        // property 'generalWarning'
        QtMocHelpers::PropertyData<bool>(55, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 32),
        // property 'turnLeft'
        QtMocHelpers::PropertyData<bool>(56, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 17),
        // property 'turnRight'
        QtMocHelpers::PropertyData<bool>(57, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 18),
        // property 'lowBeam'
        QtMocHelpers::PropertyData<bool>(58, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 19),
        // property 'highBeam'
        QtMocHelpers::PropertyData<bool>(59, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 20),
        // property 'fogLights'
        QtMocHelpers::PropertyData<bool>(60, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 21),
        // property 'cruiseActive'
        QtMocHelpers::PropertyData<bool>(61, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 22),
        // property 'laneAssist'
        QtMocHelpers::PropertyData<bool>(62, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 23),
        // property 'engineRunning'
        QtMocHelpers::PropertyData<bool>(63, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 24),
        // property 'currentGear'
        QtMocHelpers::PropertyData<int>(64, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 25),
        // property 'odometer'
        QtMocHelpers::PropertyData<double>(65, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 26),
        // property 'brakeOverheat'
        QtMocHelpers::PropertyData<bool>(66, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 27),
        // property 'canConnected'
        QtMocHelpers::PropertyData<bool>(67, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 28),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<DataModel, qt_meta_tag_ZN9DataModelE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject DataModel::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9DataModelE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9DataModelE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN9DataModelE_t>.metaTypes,
    nullptr
} };

void DataModel::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<DataModel *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->speedChanged(); break;
        case 1: _t->rpmChanged(); break;
        case 2: _t->fuelLevelChanged(); break;
        case 3: _t->engineTempChanged(); break;
        case 4: _t->oilPressureChanged(); break;
        case 5: _t->overheatingChanged(); break;
        case 6: _t->brakeSystemChanged(); break;
        case 7: _t->batteryFaultChanged(); break;
        case 8: _t->airbagFaultChanged(); break;
        case 9: _t->seatbeltChanged(); break;
        case 10: _t->checkEngineChanged(); break;
        case 11: _t->absActiveChanged(); break;
        case 12: _t->espActiveChanged(); break;
        case 13: _t->tpmsActiveChanged(); break;
        case 14: _t->fuelLowChanged(); break;
        case 15: _t->brakeWearChanged(); break;
        case 16: _t->steeringFaultChanged(); break;
        case 17: _t->turnLeftChanged(); break;
        case 18: _t->turnRightChanged(); break;
        case 19: _t->lowBeamChanged(); break;
        case 20: _t->highBeamChanged(); break;
        case 21: _t->fogLightsChanged(); break;
        case 22: _t->cruiseActiveChanged(); break;
        case 23: _t->laneAssistChanged(); break;
        case 24: _t->engineRunningChanged(); break;
        case 25: _t->currentGearChanged(); break;
        case 26: _t->odometerChanged(); break;
        case 27: _t->brakeOverheatChanged(); break;
        case 28: _t->canConnectedChanged(); break;
        case 29: _t->brakeFluidChanged(); break;
        case 30: _t->transmissionFaultChanged(); break;
        case 31: _t->transmissionOverheatChanged(); break;
        case 32: _t->generalWarningChanged(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::speedChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::rpmChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::fuelLevelChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::engineTempChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::oilPressureChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::overheatingChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::brakeSystemChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::batteryFaultChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::airbagFaultChanged, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::seatbeltChanged, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::checkEngineChanged, 10))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::absActiveChanged, 11))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::espActiveChanged, 12))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::tpmsActiveChanged, 13))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::fuelLowChanged, 14))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::brakeWearChanged, 15))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::steeringFaultChanged, 16))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::turnLeftChanged, 17))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::turnRightChanged, 18))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::lowBeamChanged, 19))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::highBeamChanged, 20))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::fogLightsChanged, 21))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::cruiseActiveChanged, 22))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::laneAssistChanged, 23))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::engineRunningChanged, 24))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::currentGearChanged, 25))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::odometerChanged, 26))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::brakeOverheatChanged, 27))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::canConnectedChanged, 28))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::brakeFluidChanged, 29))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::transmissionFaultChanged, 30))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::transmissionOverheatChanged, 31))
            return;
        if (QtMocHelpers::indexOfMethod<void (DataModel::*)()>(_a, &DataModel::generalWarningChanged, 32))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<double*>(_v) = _t->speed(); break;
        case 1: *reinterpret_cast<double*>(_v) = _t->rpm(); break;
        case 2: *reinterpret_cast<double*>(_v) = _t->fuelLevel(); break;
        case 3: *reinterpret_cast<double*>(_v) = _t->engineTemp(); break;
        case 4: *reinterpret_cast<bool*>(_v) = _t->oilPressure(); break;
        case 5: *reinterpret_cast<bool*>(_v) = _t->overheating(); break;
        case 6: *reinterpret_cast<bool*>(_v) = _t->brakeSystem(); break;
        case 7: *reinterpret_cast<bool*>(_v) = _t->batteryFault(); break;
        case 8: *reinterpret_cast<bool*>(_v) = _t->airbagFault(); break;
        case 9: *reinterpret_cast<bool*>(_v) = _t->seatbelt(); break;
        case 10: *reinterpret_cast<bool*>(_v) = _t->brakeFluid(); break;
        case 11: *reinterpret_cast<bool*>(_v) = _t->transmissionFault(); break;
        case 12: *reinterpret_cast<bool*>(_v) = _t->transmissionOverheat(); break;
        case 13: *reinterpret_cast<bool*>(_v) = _t->checkEngine(); break;
        case 14: *reinterpret_cast<bool*>(_v) = _t->absActive(); break;
        case 15: *reinterpret_cast<bool*>(_v) = _t->espActive(); break;
        case 16: *reinterpret_cast<bool*>(_v) = _t->tpmsActive(); break;
        case 17: *reinterpret_cast<bool*>(_v) = _t->fuelLow(); break;
        case 18: *reinterpret_cast<bool*>(_v) = _t->brakeWear(); break;
        case 19: *reinterpret_cast<bool*>(_v) = _t->steeringFault(); break;
        case 20: *reinterpret_cast<bool*>(_v) = _t->generalWarning(); break;
        case 21: *reinterpret_cast<bool*>(_v) = _t->turnLeft(); break;
        case 22: *reinterpret_cast<bool*>(_v) = _t->turnRight(); break;
        case 23: *reinterpret_cast<bool*>(_v) = _t->lowBeam(); break;
        case 24: *reinterpret_cast<bool*>(_v) = _t->highBeam(); break;
        case 25: *reinterpret_cast<bool*>(_v) = _t->fogLights(); break;
        case 26: *reinterpret_cast<bool*>(_v) = _t->cruiseActive(); break;
        case 27: *reinterpret_cast<bool*>(_v) = _t->laneAssist(); break;
        case 28: *reinterpret_cast<bool*>(_v) = _t->engineRunning(); break;
        case 29: *reinterpret_cast<int*>(_v) = _t->currentGear(); break;
        case 30: *reinterpret_cast<double*>(_v) = _t->odometer(); break;
        case 31: *reinterpret_cast<bool*>(_v) = _t->brakeOverheat(); break;
        case 32: *reinterpret_cast<bool*>(_v) = _t->canConnected(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setSpeed(*reinterpret_cast<double*>(_v)); break;
        case 1: _t->setRpm(*reinterpret_cast<double*>(_v)); break;
        case 2: _t->setFuelLevel(*reinterpret_cast<double*>(_v)); break;
        case 3: _t->setEngineTemp(*reinterpret_cast<double*>(_v)); break;
        case 4: _t->setOilPressure(*reinterpret_cast<bool*>(_v)); break;
        case 5: _t->setOverheating(*reinterpret_cast<bool*>(_v)); break;
        case 6: _t->setBrakeSystem(*reinterpret_cast<bool*>(_v)); break;
        case 7: _t->setBatteryFault(*reinterpret_cast<bool*>(_v)); break;
        case 8: _t->setAirbagFault(*reinterpret_cast<bool*>(_v)); break;
        case 9: _t->setSeatbelt(*reinterpret_cast<bool*>(_v)); break;
        case 10: _t->setBrakeFluid(*reinterpret_cast<bool*>(_v)); break;
        case 11: _t->setTransmissionFault(*reinterpret_cast<bool*>(_v)); break;
        case 12: _t->setTransmissionOverheat(*reinterpret_cast<bool*>(_v)); break;
        case 13: _t->setCheckEngine(*reinterpret_cast<bool*>(_v)); break;
        case 14: _t->setAbsActive(*reinterpret_cast<bool*>(_v)); break;
        case 15: _t->setEspActive(*reinterpret_cast<bool*>(_v)); break;
        case 16: _t->setTpmsActive(*reinterpret_cast<bool*>(_v)); break;
        case 17: _t->setFuelLow(*reinterpret_cast<bool*>(_v)); break;
        case 18: _t->setBrakeWear(*reinterpret_cast<bool*>(_v)); break;
        case 19: _t->setSteeringFault(*reinterpret_cast<bool*>(_v)); break;
        case 20: _t->setGeneralWarning(*reinterpret_cast<bool*>(_v)); break;
        case 21: _t->setTurnLeft(*reinterpret_cast<bool*>(_v)); break;
        case 22: _t->setTurnRight(*reinterpret_cast<bool*>(_v)); break;
        case 23: _t->setLowBeam(*reinterpret_cast<bool*>(_v)); break;
        case 24: _t->setHighBeam(*reinterpret_cast<bool*>(_v)); break;
        case 25: _t->setFogLights(*reinterpret_cast<bool*>(_v)); break;
        case 26: _t->setCruiseActive(*reinterpret_cast<bool*>(_v)); break;
        case 27: _t->setLaneAssist(*reinterpret_cast<bool*>(_v)); break;
        case 28: _t->setEngineRunning(*reinterpret_cast<bool*>(_v)); break;
        case 29: _t->setCurrentGear(*reinterpret_cast<int*>(_v)); break;
        case 30: _t->setOdometer(*reinterpret_cast<double*>(_v)); break;
        case 31: _t->setBrakeOverheat(*reinterpret_cast<bool*>(_v)); break;
        case 32: _t->setCanConnected(*reinterpret_cast<bool*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *DataModel::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *DataModel::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9DataModelE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int DataModel::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 33)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 33;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 33)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 33;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 33;
    }
    return _id;
}

// SIGNAL 0
void DataModel::speedChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void DataModel::rpmChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void DataModel::fuelLevelChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void DataModel::engineTempChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void DataModel::oilPressureChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void DataModel::overheatingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void DataModel::brakeSystemChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void DataModel::batteryFaultChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}

// SIGNAL 8
void DataModel::airbagFaultChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 8, nullptr);
}

// SIGNAL 9
void DataModel::seatbeltChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}

// SIGNAL 10
void DataModel::checkEngineChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 10, nullptr);
}

// SIGNAL 11
void DataModel::absActiveChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 11, nullptr);
}

// SIGNAL 12
void DataModel::espActiveChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 12, nullptr);
}

// SIGNAL 13
void DataModel::tpmsActiveChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 13, nullptr);
}

// SIGNAL 14
void DataModel::fuelLowChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 14, nullptr);
}

// SIGNAL 15
void DataModel::brakeWearChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 15, nullptr);
}

// SIGNAL 16
void DataModel::steeringFaultChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 16, nullptr);
}

// SIGNAL 17
void DataModel::turnLeftChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 17, nullptr);
}

// SIGNAL 18
void DataModel::turnRightChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 18, nullptr);
}

// SIGNAL 19
void DataModel::lowBeamChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 19, nullptr);
}

// SIGNAL 20
void DataModel::highBeamChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 20, nullptr);
}

// SIGNAL 21
void DataModel::fogLightsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 21, nullptr);
}

// SIGNAL 22
void DataModel::cruiseActiveChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 22, nullptr);
}

// SIGNAL 23
void DataModel::laneAssistChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 23, nullptr);
}

// SIGNAL 24
void DataModel::engineRunningChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 24, nullptr);
}

// SIGNAL 25
void DataModel::currentGearChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 25, nullptr);
}

// SIGNAL 26
void DataModel::odometerChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 26, nullptr);
}

// SIGNAL 27
void DataModel::brakeOverheatChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 27, nullptr);
}

// SIGNAL 28
void DataModel::canConnectedChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 28, nullptr);
}

// SIGNAL 29
void DataModel::brakeFluidChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 29, nullptr);
}

// SIGNAL 30
void DataModel::transmissionFaultChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 30, nullptr);
}

// SIGNAL 31
void DataModel::transmissionOverheatChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 31, nullptr);
}

// SIGNAL 32
void DataModel::generalWarningChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 32, nullptr);
}
QT_WARNING_POP
