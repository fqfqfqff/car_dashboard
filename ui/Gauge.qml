// =============================================================================
// Gauge.qml — QML-обёртка над GaugeItem. Переработка v5.
//
// ИСПРАВЛЕНИЯ vs. v4:
//   • startSweep() теперь устанавливает _sweepDone = false и запускает анимацию
//   • glowIntensity плавно нарастает через _smoothGlow
//   • Мигание красной зоны работает корректно
// =============================================================================

import QtQuick 2.15
import CarDashboard 1.0

Item {
   id: root

   property double value:         0
   property double minValue:      0
   property double maxValue:      300
   property double step:          20.0
   property color  arcColor:      "#FF3B30"
   property double dangerZone:    0.85
   property string unit:          ""
   property string centerText:    ""
   property double glowIntensity: 0.0

   signal sweepFinished()

   property double _animValue:  0.0
   property bool   _sweepDone:  false
   property double _prevValue:  0.0

   // Плавное появление подсветки
   property double _smoothGlow: 0.0
   Behavior on _smoothGlow {
       NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
   }
   onGlowIntensityChanged: {
       if (_sweepDone) _smoothGlow = glowIntensity
   }

   // ── STARTUP SWEEP ─────────────────────────────────────────────────────────
   SequentialAnimation {
       id: sweepAnim
       running: false

       // Фаза 1: разгон 0 → max
       NumberAnimation {
           target: root; property: "_animValue"
           to: root.maxValue
           duration:    1500
           easing.type: Easing.InOutCubic
       }

       // Пауза на максимуме
       PauseAnimation { duration: 500 }

       // Фаза 2: возврат к нулю
       NumberAnimation {
           target: root; property: "_animValue"
           to: 0
           duration:    1000
           easing.type: Easing.OutCubic
       }

       onStopped: {
           root._sweepDone = true
           // Плавный переход к реальному значению (которое могло прийти с CAN пока шёл sweep)
           snapToValue.to = root.value
           snapToValue.start()
           root.sweepFinished()
       }
   }

   // Плавный переход после sweep
   NumberAnimation {
       id: snapToValue
       target: root; property: "_animValue"
       duration: 500
       easing.type: Easing.OutCubic
       running: false
   }

   // ── НОРМАЛЬНАЯ АНИМАЦИЯ ИГЛЫ ──────────────────────────────────────────────
   Behavior on _animValue {
       enabled: root._sweepDone && !snapToValue.running
       NumberAnimation {
           duration:    180
           easing.type: Easing.OutCubic
       }
   }

   onValueChanged: {
       // Всегда запоминаем последнее значение - даже во время sweep
       _prevValue = value

       if (!_sweepDone) {
           // Во время sweep не двигаем иглу, но snapToValue будет
           // использовать актуальное value когда sweep закончится
           return
       }

       const delta = value - _animValue
       const threshold = maxValue * 0.001

       if (Math.abs(delta) < threshold) {
           _animValue = value
       } else if (Math.abs(delta) > maxValue * 0.04) {
           const overshoot = (delta > 0 ? 1 : -1) * maxValue * 0.012
           _animValue = Math.min(maxValue, Math.max(minValue, value + overshoot))
           overshootTimer.restart()
       } else {
           _animValue = value
       }
   }

   Timer {
       id: overshootTimer
       interval: 55
       repeat: false
       onTriggered: root._animValue = root.value
   }

   // ── МИГАНИЕ КРАСНОЙ ЗОНЫ ─────────────────────────────────────────────────
   property bool _blinkState: false
   readonly property bool _inDanger:
       _sweepDone && (_animValue / maxValue >= dangerZone)

   Timer {
       id: dangerBlinkTimer
       interval: 350
       running:  root._inDanger
       repeat:   true
       onTriggered: root._blinkState = !root._blinkState
       onRunningChanged: { if (!running) root._blinkState = false }
   }

   // ── GaugeItem (C++ QPainter) ──────────────────────────────────────────────
   GaugeItem {
       anchors.fill: parent

       value:         root._animValue
       minValue:      root.minValue
       maxValue:      root.maxValue
       step:          root.step
       arcColor:      root.arcColor
       dangerZone:    root.dangerZone
       unit:          root.unit
       centerText:    root.centerText
       glowIntensity: root._smoothGlow
       dangerBlink:   root._blinkState
   }

   // ── ПУБЛИЧНЫЙ МЕТОД ДЛЯ ЗАПУСКА SWEEP ─────────────────────────────────────
   function startSweep() {
       _sweepDone  = false
       _animValue  = 0.0
       _smoothGlow = 0.0
       sweepAnim.start()
   }
}
