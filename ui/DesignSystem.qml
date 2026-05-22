// =============================================================================
// DesignSystem.qml — единый источник всех дизайн-токенов
//
// Подключай в любом QML как:
//   import "." as DS   (если в той же папке)
//
// Использование:
//   color: DS.colorCritical
//   font.pixelSize: DS.fontSizeLarge(parent.height)
//
// Принцип: ОДИН файл → нет рассинхронизации токенов между компонентами
// =============================================================================

pragma Singleton
import QtQuick 2.15

QtObject {

    // ── ЦВЕТА ─────────────────────────────────────────────────────────────────

    // Фоны (матовые, тёмные)
    readonly property color bgPrimary:   "#0A0A0A"   // главный фон
    readonly property color bgSecondary: "#121212"   // поверхность 2-го уровня
    readonly property color bgSurface:   "#1A1A1A"   // поверхность 3-го уровня
    readonly property color bgCard:      "#111111"   // карточки/панели

    // Текст
    readonly property color textPrimary:   "#FFFFFF"   // основной (100% opacity)
    readonly property color textSecondary: "#B0B0B0"   // вторичный
    readonly property color textDim:       "#6A6A6A"   // приглушённый
    readonly property color textInactive:  "#333333"   // неактивный

    // Индикаторы — строгая иерархия
    readonly property color critical:   "#FF3B30"   // КРИТИЧЕСКИЙ (красный)
    readonly property color warning:    "#FFCC00"   // ПРЕДУПРЕЖДЕНИЕ (жёлтый)
    readonly property color infoBlue:   "#0A84FF"   // ИНФОРМАЦИЯ — синий
    readonly property color infoGreen:  "#30D158"   // ИНФОРМАЦИЯ — зелёный (ON, CRUISE)

    // Разделители
    readonly property color divider:    "#242424"
    readonly property color border:     "#2A2A2A"

    // ── ОТСТУПЫ (система 4px) ─────────────────────────────────────────────────
    readonly property real sp4:  4
    readonly property real sp8:  8
    readonly property real sp12: 12
    readonly property real sp16: 16
    readonly property real sp24: 24
    readonly property real sp32: 32

    // ── ШРИФТЫ ───────────────────────────────────────────────────────────────
    readonly property string fontMain: "Microgramma"

    // Пиксельные размеры: функции от высоты контейнера
    function fontHuge(h)   { return h * 0.185 }  // главное число (скорость)
    function fontXL(h)     { return h * 0.075 }  // передача
    function fontLarge(h)  { return h * 0.052 }  // пробег, расход
    function fontMedium(h) { return h * 0.038 }  // статус, ON/OFF
    function fontSmall(h)  { return h * 0.028 }  // метки единиц
    function fontTiny(h)   { return h * 0.022 }  // подписи

    // ── АНИМАЦИИ (длительности в мс) ─────────────────────────────────────────
    readonly property int animFast:   80    // мгновенные реакции (цвет кнопки)
    readonly property int animNormal: 200   // стандартные переходы
    readonly property int animSlow:   400   // fade-in индикаторов
    readonly property int animBlink:  500   // период мигания (ISO: 60-120 bpm)

    // ── РАДИУСЫ ───────────────────────────────────────────────────────────────
    readonly property real radiusSmall:  6
    readonly property real radiusMedium: 12
    readonly property real radiusLarge:  18
}
