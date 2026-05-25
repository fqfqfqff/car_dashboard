/****************************************************************************
** Meta object code from reading C++ file 'GaugeItem.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../ui/GaugeItem.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'GaugeItem.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN9GaugeItemE_t {};
} // unnamed namespace

template <> constexpr inline auto GaugeItem::qt_create_metaobjectdata<qt_meta_tag_ZN9GaugeItemE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "GaugeItem",
        "valueChanged",
        "",
        "minValueChanged",
        "maxValueChanged",
        "stepChanged",
        "arcColorChanged",
        "dangerZoneChanged",
        "unitChanged",
        "centerTextChanged",
        "glowIntensityChanged",
        "dangerBlinkChanged",
        "value",
        "minValue",
        "maxValue",
        "step",
        "arcColor",
        "QColor",
        "dangerZone",
        "unit",
        "centerText",
        "glowIntensity",
        "dangerBlink"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'valueChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'minValueChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'maxValueChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'stepChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'arcColorChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'dangerZoneChanged'
        QtMocHelpers::SignalData<void()>(7, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'unitChanged'
        QtMocHelpers::SignalData<void()>(8, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'centerTextChanged'
        QtMocHelpers::SignalData<void()>(9, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'glowIntensityChanged'
        QtMocHelpers::SignalData<void()>(10, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'dangerBlinkChanged'
        QtMocHelpers::SignalData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'value'
        QtMocHelpers::PropertyData<double>(12, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'minValue'
        QtMocHelpers::PropertyData<double>(13, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'maxValue'
        QtMocHelpers::PropertyData<double>(14, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'step'
        QtMocHelpers::PropertyData<double>(15, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'arcColor'
        QtMocHelpers::PropertyData<QColor>(16, 0x80000000 | 17, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 4),
        // property 'dangerZone'
        QtMocHelpers::PropertyData<double>(18, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'unit'
        QtMocHelpers::PropertyData<QString>(19, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'centerText'
        QtMocHelpers::PropertyData<QString>(20, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
        // property 'glowIntensity'
        QtMocHelpers::PropertyData<double>(21, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 8),
        // property 'dangerBlink'
        QtMocHelpers::PropertyData<bool>(22, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 9),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<GaugeItem, qt_meta_tag_ZN9GaugeItemE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject GaugeItem::staticMetaObject = { {
    QMetaObject::SuperData::link<QQuickPaintedItem::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9GaugeItemE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9GaugeItemE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN9GaugeItemE_t>.metaTypes,
    nullptr
} };

void GaugeItem::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<GaugeItem *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->valueChanged(); break;
        case 1: _t->minValueChanged(); break;
        case 2: _t->maxValueChanged(); break;
        case 3: _t->stepChanged(); break;
        case 4: _t->arcColorChanged(); break;
        case 5: _t->dangerZoneChanged(); break;
        case 6: _t->unitChanged(); break;
        case 7: _t->centerTextChanged(); break;
        case 8: _t->glowIntensityChanged(); break;
        case 9: _t->dangerBlinkChanged(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::valueChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::minValueChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::maxValueChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::stepChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::arcColorChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::dangerZoneChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::unitChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::centerTextChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::glowIntensityChanged, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (GaugeItem::*)()>(_a, &GaugeItem::dangerBlinkChanged, 9))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<double*>(_v) = _t->value(); break;
        case 1: *reinterpret_cast<double*>(_v) = _t->minValue(); break;
        case 2: *reinterpret_cast<double*>(_v) = _t->maxValue(); break;
        case 3: *reinterpret_cast<double*>(_v) = _t->step(); break;
        case 4: *reinterpret_cast<QColor*>(_v) = _t->arcColor(); break;
        case 5: *reinterpret_cast<double*>(_v) = _t->dangerZone(); break;
        case 6: *reinterpret_cast<QString*>(_v) = _t->unit(); break;
        case 7: *reinterpret_cast<QString*>(_v) = _t->centerText(); break;
        case 8: *reinterpret_cast<double*>(_v) = _t->glowIntensity(); break;
        case 9: *reinterpret_cast<bool*>(_v) = _t->dangerBlink(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setValue(*reinterpret_cast<double*>(_v)); break;
        case 1: _t->setMinValue(*reinterpret_cast<double*>(_v)); break;
        case 2: _t->setMaxValue(*reinterpret_cast<double*>(_v)); break;
        case 3: _t->setStep(*reinterpret_cast<double*>(_v)); break;
        case 4: _t->setArcColor(*reinterpret_cast<QColor*>(_v)); break;
        case 5: _t->setDangerZone(*reinterpret_cast<double*>(_v)); break;
        case 6: _t->setUnit(*reinterpret_cast<QString*>(_v)); break;
        case 7: _t->setCenterText(*reinterpret_cast<QString*>(_v)); break;
        case 8: _t->setGlowIntensity(*reinterpret_cast<double*>(_v)); break;
        case 9: _t->setDangerBlink(*reinterpret_cast<bool*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *GaugeItem::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *GaugeItem::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9GaugeItemE_t>.strings))
        return static_cast<void*>(this);
    return QQuickPaintedItem::qt_metacast(_clname);
}

int GaugeItem::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QQuickPaintedItem::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 10)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 10;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 10)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 10;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 10;
    }
    return _id;
}

// SIGNAL 0
void GaugeItem::valueChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void GaugeItem::minValueChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void GaugeItem::maxValueChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void GaugeItem::stepChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void GaugeItem::arcColorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void GaugeItem::dangerZoneChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void GaugeItem::unitChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void GaugeItem::centerTextChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}

// SIGNAL 8
void GaugeItem::glowIntensityChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 8, nullptr);
}

// SIGNAL 9
void GaugeItem::dangerBlinkChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}
QT_WARNING_POP
