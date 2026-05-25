// =============================================================================
// main.qml — точка входа QML
//
// ИЗМЕНЕНИЯ vs. оригинала:
//   1. Импорт папки "." для доступа к singleton'ам (BlinkController, DesignSystem)
//   2. dataModel доступен как контекстное свойство (из C++ main.cpp)
//   3. Размер окна: 3840×2160 (4K), масштабируется до любого разрешения
//
// ТРЕБОВАНИЕ К main.cpp:
//   engine.addImportPath("qrc:/");  // чтобы qmldir находился
//   (или engine.addImportPath(":/ui") если qmldir в ресурсах под /ui)
// =============================================================================

import QtQuick 2.15
import QtQuick.Window 2.15
import "."   // регистрирует BlinkController и DesignSystem как singleton

Window {
    id: root

    width:   3840
    height:  2160
    visible: true
    title:   "Приборная панель"
    color:   "#000000"

    // Шрифты (загружаются один раз, доступны везде)
    FontLoader { source: "qrc:/assets/fonts/Microgramma-Normal.ttf" }
    FontLoader { source: "qrc:/assets/fonts/Inter-Regular.ttf" }
    FontLoader { source: "qrc:/assets/fonts/Inter-Bold.ttf" }
    FontLoader { source: "qrc:/assets/fonts/Inter-SemiBold.ttf" }

    // Главный layout
    Dashboard { anchors.fill: parent }
}
