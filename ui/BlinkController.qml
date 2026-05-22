// =============================================================================
// BlinkController.qml — глобальный синхронный контроллер мигания v2
//
// ПРИНЦИПЫ:
//   • Один Timer → один blinkState → нет рассинхрона (drift невозможен)
//   • Таймер работает только когда нужно мигание (экономия ресурсов)
//   • При остановке таймера — сброс в ON (следующий цикл начинается с включённого)
//   • Частота 500ms (60 bpm) — нижняя граница ISO 3833
// =============================================================================

pragma Singleton
import QtQuick 2.15

QtObject {
    id: root

    // Текущее состояние мигания (true = ON, false = OFF)
    property bool blinkState: true

    // Нужно ли мигание прямо сейчас?
    readonly property bool blinkNeeded: dataModel.turnLeft || dataModel.turnRight

    // Вычисляемые состояния для каждого индикатора поворота
    readonly property bool showLeft:   dataModel.turnLeft  && blinkState
    readonly property bool showRight:  dataModel.turnRight && blinkState
    // Аварийка — оба сигнала одновременно, синхронно
    readonly property bool showHazard: dataModel.turnLeft  && dataModel.turnRight && blinkState

    // ── Единый таймер ────────────────────────────────────────────────────────
    property var _timer: Timer {
        interval: 500
        running:  root.blinkNeeded
        repeat:   true
        onTriggered: root.blinkState = !root.blinkState

        // При остановке — всегда сброс в ON.
        // Гарантирует что следующий цикл начнётся с включённого состояния,
        // а не зависнет в OFF.
        onRunningChanged: {
            if (!running) root.blinkState = true
        }
    }
}
