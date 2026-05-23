import QtQuick 2.15
import CarDashboard 1.0

Item {
    id: root

    property double value:          0
    property double minValue:       0
    property double maxValue:       300
    property double step:           20.0
    property color  arcColor:       "#FF3B30"
    property double dangerZone:     0.85
    property string unit:           ""
    property string centerText:     ""
    property double glowIntensity:  0.0

    // Внутренняя дуга
    property bool   showInnerArc:   false
    property string innerArcType:   "temp"    // "temp" или "fuel"
    property double innerArcValue:  0.0
    property double innerArcMin:    0.0
    property double innerArcMax:    100.0

    // Маленькие индикаторы внутри циферблата
    property bool   indicator1Active: false
    property bool   indicator2Active: false
    property string indicator1Icon:   ""
    property string indicator2Icon:   ""

    signal sweepFinished()

    property bool   sweeping:    false
    property double _animValue:  0.0
    property bool   _sweepDone:  false
    property double _prevValue:  0.0
    property double _smoothGlow: 0.0

    Behavior on _smoothGlow {
        NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
    }
    onGlowIntensityChanged: {
        if (_sweepDone) _smoothGlow = glowIntensity
    }

    SequentialAnimation {
        id: sweepAnim
        running: false
        NumberAnimation {
            target: root; property: "_animValue"
            to: root.maxValue
            duration: 1400; easing.type: Easing.InOutCubic
        }
        PauseAnimation { duration: 450 }
        NumberAnimation {
            target: root; property: "_animValue"
            to: 0
            duration: 900; easing.type: Easing.OutCubic
        }
        onStopped: {
            root._sweepDone = true
            root.sweeping   = false
            snapToValue.to  = root.value
            snapToValue.start()
            root.sweepFinished()
        }
    }

    NumberAnimation {
        id: snapToValue
        target: root; property: "_animValue"
        duration: 450; easing.type: Easing.OutCubic
        running: false
    }

    Behavior on _animValue {
        enabled: root._sweepDone && !snapToValue.running
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    onValueChanged: {
        _prevValue = value
        if (!_sweepDone) return
        const delta     = value - _animValue
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
        id: overshootTimer; interval: 55; repeat: false
        onTriggered: root._animValue = root.value
    }

    property bool _blinkState: false
    readonly property bool _inDanger:
        _sweepDone && (_animValue / maxValue >= dangerZone)

    Timer {
        id: dangerBlinkTimer
        interval: 340; running: root._inDanger; repeat: true
        onTriggered: root._blinkState = !root._blinkState
        onRunningChanged: { if (!running) root._blinkState = false }
    }

    GaugeItem {
        anchors.fill: parent

        value:          root._animValue
        minValue:       root.minValue
        maxValue:       root.maxValue
        step:           root.step
        arcColor:       root.arcColor
        dangerZone:     root.dangerZone
        unit:           root.unit
        centerText:     root.centerText
        glowIntensity:  root._smoothGlow
        dangerBlink:    root._blinkState

        showInnerArc:   root.showInnerArc
        innerArcType:   root.innerArcType
        innerArcValue:  root.innerArcValue
        innerArcMin:    root.innerArcMin
        innerArcMax:    root.innerArcMax

        indicator1Active: root.indicator1Active
        indicator2Active: root.indicator2Active
        indicator1Icon:   root.indicator1Icon
        indicator2Icon:   root.indicator2Icon
    }

    function startSweep() {
        _sweepDone  = false
        _animValue  = 0.0
        _smoothGlow = 0.0
        sweeping    = true
        sweepAnim.start()
    }
}
