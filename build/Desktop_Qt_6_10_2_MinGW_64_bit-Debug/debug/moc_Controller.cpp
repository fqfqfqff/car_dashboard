/****************************************************************************
** Meta object code from reading C++ file 'Controller.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../backend/Controller.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'Controller.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN10ControllerE_t {};
} // unnamed namespace

template <> constexpr inline auto Controller::qt_create_metaobjectdata<qt_meta_tag_ZN10ControllerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "Controller",
        "gasChanged",
        "",
        "v",
        "brakeChanged",
        "clutchChanged",
        "handbrakeChanged",
        "turnLeftChanged",
        "turnRightChanged",
        "hazardChanged",
        "lowBeamChanged",
        "highBeamChanged",
        "fogLightsChanged",
        "cruiseChanged",
        "engineStarted",
        "engineStopped",
        "testIndicator",
        "name",
        "value",
        "setGas",
        "setBrake",
        "setClutch",
        "toggleHandbrake",
        "setTurnLeft",
        "setTurnRight",
        "setHazard",
        "setLowBeam",
        "setHighBeam",
        "setFogLights",
        "toggleCruise",
        "startEngine",
        "stopEngine",
        "testOilPressure",
        "testOverheating",
        "testBrakeSystem",
        "testBattery",
        "testAirbag",
        "testSeatbelt",
        "testCheckEngine",
        "testAbs",
        "testEsp",
        "testTpms",
        "testFuelLow",
        "testBrakeWear",
        "testSteeringFault",
        "testBrakeFluid",
        "testTransmissionFault",
        "testTransmissionOverheat",
        "testGeneralWarning"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'gasChanged'
        QtMocHelpers::SignalData<void(float)>(1, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 3 },
        }}),
        // Signal 'brakeChanged'
        QtMocHelpers::SignalData<void(float)>(4, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 3 },
        }}),
        // Signal 'clutchChanged'
        QtMocHelpers::SignalData<void(float)>(5, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 3 },
        }}),
        // Signal 'handbrakeChanged'
        QtMocHelpers::SignalData<void(bool)>(6, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'turnLeftChanged'
        QtMocHelpers::SignalData<void(bool)>(7, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'turnRightChanged'
        QtMocHelpers::SignalData<void(bool)>(8, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'hazardChanged'
        QtMocHelpers::SignalData<void(bool)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'lowBeamChanged'
        QtMocHelpers::SignalData<void(bool)>(10, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'highBeamChanged'
        QtMocHelpers::SignalData<void(bool)>(11, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'fogLightsChanged'
        QtMocHelpers::SignalData<void(bool)>(12, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'cruiseChanged'
        QtMocHelpers::SignalData<void(bool)>(13, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'engineStarted'
        QtMocHelpers::SignalData<void()>(14, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'engineStopped'
        QtMocHelpers::SignalData<void()>(15, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'testIndicator'
        QtMocHelpers::SignalData<void(const QString &, bool)>(16, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 17 }, { QMetaType::Bool, 18 },
        }}),
        // Slot 'setGas'
        QtMocHelpers::SlotData<void(float)>(19, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 3 },
        }}),
        // Slot 'setBrake'
        QtMocHelpers::SlotData<void(float)>(20, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 3 },
        }}),
        // Slot 'setClutch'
        QtMocHelpers::SlotData<void(float)>(21, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 3 },
        }}),
        // Slot 'toggleHandbrake'
        QtMocHelpers::SlotData<void()>(22, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'setTurnLeft'
        QtMocHelpers::SlotData<void(bool)>(23, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Slot 'setTurnRight'
        QtMocHelpers::SlotData<void(bool)>(24, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Slot 'setHazard'
        QtMocHelpers::SlotData<void(bool)>(25, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Slot 'setLowBeam'
        QtMocHelpers::SlotData<void(bool)>(26, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Slot 'setHighBeam'
        QtMocHelpers::SlotData<void(bool)>(27, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Slot 'setFogLights'
        QtMocHelpers::SlotData<void(bool)>(28, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Slot 'toggleCruise'
        QtMocHelpers::SlotData<void()>(29, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'startEngine'
        QtMocHelpers::SlotData<void()>(30, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'stopEngine'
        QtMocHelpers::SlotData<void()>(31, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testOilPressure'
        QtMocHelpers::SlotData<void()>(32, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testOverheating'
        QtMocHelpers::SlotData<void()>(33, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testBrakeSystem'
        QtMocHelpers::SlotData<void()>(34, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testBattery'
        QtMocHelpers::SlotData<void()>(35, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testAirbag'
        QtMocHelpers::SlotData<void()>(36, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testSeatbelt'
        QtMocHelpers::SlotData<void()>(37, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testCheckEngine'
        QtMocHelpers::SlotData<void()>(38, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testAbs'
        QtMocHelpers::SlotData<void()>(39, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testEsp'
        QtMocHelpers::SlotData<void()>(40, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testTpms'
        QtMocHelpers::SlotData<void()>(41, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testFuelLow'
        QtMocHelpers::SlotData<void()>(42, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testBrakeWear'
        QtMocHelpers::SlotData<void()>(43, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testSteeringFault'
        QtMocHelpers::SlotData<void()>(44, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testBrakeFluid'
        QtMocHelpers::SlotData<void()>(45, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testTransmissionFault'
        QtMocHelpers::SlotData<void()>(46, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testTransmissionOverheat'
        QtMocHelpers::SlotData<void()>(47, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'testGeneralWarning'
        QtMocHelpers::SlotData<void()>(48, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<Controller, qt_meta_tag_ZN10ControllerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject Controller::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10ControllerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10ControllerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN10ControllerE_t>.metaTypes,
    nullptr
} };

void Controller::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<Controller *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->gasChanged((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 1: _t->brakeChanged((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 2: _t->clutchChanged((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 3: _t->handbrakeChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 4: _t->turnLeftChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 5: _t->turnRightChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 6: _t->hazardChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 7: _t->lowBeamChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 8: _t->highBeamChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 9: _t->fogLightsChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 10: _t->cruiseChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 11: _t->engineStarted(); break;
        case 12: _t->engineStopped(); break;
        case 13: _t->testIndicator((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 14: _t->setGas((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 15: _t->setBrake((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 16: _t->setClutch((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 17: _t->toggleHandbrake(); break;
        case 18: _t->setTurnLeft((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 19: _t->setTurnRight((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 20: _t->setHazard((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 21: _t->setLowBeam((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 22: _t->setHighBeam((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 23: _t->setFogLights((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 24: _t->toggleCruise(); break;
        case 25: _t->startEngine(); break;
        case 26: _t->stopEngine(); break;
        case 27: _t->testOilPressure(); break;
        case 28: _t->testOverheating(); break;
        case 29: _t->testBrakeSystem(); break;
        case 30: _t->testBattery(); break;
        case 31: _t->testAirbag(); break;
        case 32: _t->testSeatbelt(); break;
        case 33: _t->testCheckEngine(); break;
        case 34: _t->testAbs(); break;
        case 35: _t->testEsp(); break;
        case 36: _t->testTpms(); break;
        case 37: _t->testFuelLow(); break;
        case 38: _t->testBrakeWear(); break;
        case 39: _t->testSteeringFault(); break;
        case 40: _t->testBrakeFluid(); break;
        case 41: _t->testTransmissionFault(); break;
        case 42: _t->testTransmissionOverheat(); break;
        case 43: _t->testGeneralWarning(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(float )>(_a, &Controller::gasChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(float )>(_a, &Controller::brakeChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(float )>(_a, &Controller::clutchChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(bool )>(_a, &Controller::handbrakeChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(bool )>(_a, &Controller::turnLeftChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(bool )>(_a, &Controller::turnRightChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(bool )>(_a, &Controller::hazardChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(bool )>(_a, &Controller::lowBeamChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(bool )>(_a, &Controller::highBeamChanged, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(bool )>(_a, &Controller::fogLightsChanged, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(bool )>(_a, &Controller::cruiseChanged, 10))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)()>(_a, &Controller::engineStarted, 11))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)()>(_a, &Controller::engineStopped, 12))
            return;
        if (QtMocHelpers::indexOfMethod<void (Controller::*)(const QString & , bool )>(_a, &Controller::testIndicator, 13))
            return;
    }
}

const QMetaObject *Controller::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *Controller::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10ControllerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int Controller::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 44)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 44;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 44)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 44;
    }
    return _id;
}

// SIGNAL 0
void Controller::gasChanged(float _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
}

// SIGNAL 1
void Controller::brakeChanged(float _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}

// SIGNAL 2
void Controller::clutchChanged(float _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1);
}

// SIGNAL 3
void Controller::handbrakeChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 3, nullptr, _t1);
}

// SIGNAL 4
void Controller::turnLeftChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 4, nullptr, _t1);
}

// SIGNAL 5
void Controller::turnRightChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 5, nullptr, _t1);
}

// SIGNAL 6
void Controller::hazardChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 6, nullptr, _t1);
}

// SIGNAL 7
void Controller::lowBeamChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 7, nullptr, _t1);
}

// SIGNAL 8
void Controller::highBeamChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 8, nullptr, _t1);
}

// SIGNAL 9
void Controller::fogLightsChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 9, nullptr, _t1);
}

// SIGNAL 10
void Controller::cruiseChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 10, nullptr, _t1);
}

// SIGNAL 11
void Controller::engineStarted()
{
    QMetaObject::activate(this, &staticMetaObject, 11, nullptr);
}

// SIGNAL 12
void Controller::engineStopped()
{
    QMetaObject::activate(this, &staticMetaObject, 12, nullptr);
}

// SIGNAL 13
void Controller::testIndicator(const QString & _t1, bool _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 13, nullptr, _t1, _t2);
}
QT_WARNING_POP
