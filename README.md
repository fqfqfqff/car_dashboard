# CarDashboard Android

Android-приложение приборной панели на `Qt/QML + C++` для Android LCD дисплея автомобиля.

Текущий проект переделан под Android-first сценарий:

- `Qt 6.5+`
- `targetSdkVersion 34`
- `minSdkVersion 29`
- `landscape`
- `fullscreen immersive mode`
- `OpenGL/Qt Quick hardware rendering`
- `Bluetooth ELM327 OBD2` вместо `Kvaser/CANlib`

## Что изменено

### 1. Убраны desktop/CAN зависимости

- удалены зависимости на `canlib32.dll`
- удалена логика `Kvaser API`
- старый `CANReader` полностью заменён на Bluetooth/ELM327 транспорт
- проект больше не зависит от Windows/macOS-only CAN слоя

### 2. Новый поток данных

Источник данных теперь такой:

`Bluetooth RFCOMM -> ELM327 -> OBD2 PID -> CANReader -> DataModel -> QML`

Реализация использует:

- `QBluetoothSocket`
- `QBluetoothDeviceDiscoveryAgent`
- асинхронную работу через сигналы/слоты
- авто-подключение
- авто-переподключение
- неблокирующий polling PID

### 3. Реализованные OBD2 PID

- `010C` RPM
- `010D` vehicle speed
- `0105` coolant temperature
- `012F` fuel level
- `0142` control module voltage
- `0104` calculated engine load

### 4. DataModel расширен

В `DataModel` добавлены:

- `batteryVoltage`
- `engineLoad`

Они доступны напрямую из QML как обычные `Q_PROPERTY`.

### 5. UI сохранён

Сохранено без переработки дизайна:

- Audi RS5-style layout
- существующие `GaugeItem`
- circular gauges
- анимации запуска
- 4K-oriented layout

Для live OBD2 режима центр тахометра не показывает фиктивную передачу:

- в стандартном OBD2 gear не передаётся
- если внешнего gear-сигнала нет, индикатор передачи остаётся пустым

## Важные файлы

- `main.cpp` — Android bootstrap, OpenGL backend, immersive mode
- `ui/CANReader.h/.cpp` — Bluetooth ELM327 + OBD2 polling
- `backend/DataModel.h/.cpp` — модель данных для QML
- `CarDashboard_android.pro` — qmake-конфигурация под Android ARM64
- `android/AndroidManifest.xml` — Android manifest
- `android/res/xml/qtprovider_paths.xml` — FileProvider paths

## Поведение приложения

### Авто-подключение

При старте приложение:

1. запрашивает runtime permissions для Bluetooth
2. пытается подключиться к сохранённому MAC-адресу ELM327
3. если адрес не сохранён, сканирует classic Bluetooth устройства
4. ищет устройства по именам вроде `ELM`, `OBD`, `V-LINK`, `iCar`
5. после подключения отправляет init-команды ELM327:
   - `ATZ`
   - `ATE0`
   - `ATL0`
   - `ATS0`
   - `ATH0`
   - `ATSP0`
6. затем запускает циклический polling PID

Если Bluetooth-соединение пропадает, запускается автоматический reconnect.

### Сохранённый адаптер

После первого успешного подключения адрес сохраняется в `QSettings`.

Также можно задать его через переменные окружения:

- `CAR_DASHBOARD_ELM327_ADDRESS=AA:BB:CC:DD:EE:FF`
- `CAR_DASHBOARD_ELM327_NAME=V-LINK`
- `CAR_DASHBOARD_ELM327_POLL_MS=120`

## Настройка Qt Android Kit

### 1. Установить Qt для Android

Через `Qt Maintenance Tool` установи:

- `Qt 6.5+` или новее
- Android kit для `arm64-v8a`
- `Qt Creator`

Если у тебя уже стоит только desktop Qt, этого недостаточно. Нужен именно Android kit, например:

- `Qt 6.10.x for Android ARM64`

### 2. Установить Android SDK / NDK / JDK

Рекомендуемая схема:

- поставить `Android Studio`
- установить `Android SDK Platform 34`
- установить `Android SDK Build-Tools 34.x`
- установить `Android Platform-Tools`
- установить `Android SDK Command-line Tools`
- установить `NDK`, совместимый с выбранным Qt Android kit
- использовать `JDK 17`

Практически самый безопасный вариант:

- сначала установить Android kit через `Qt Maintenance Tool`
- затем в `Qt Creator -> Preferences -> Devices -> Android`
  указать пути к `SDK`, `NDK`, `JDK`
- использовать тот `NDK`, который Qt Creator отмечает как совместимый для выбранного Qt

### 3. Проверить Android kit в Qt Creator

В `Qt Creator`:

1. `Edit -> Preferences -> Devices -> Android`
2. укажи:
   - `SDK location`
   - `NDK location`
   - `JDK location`
3. дождись успешной проверки toolchain
4. открой `CarDashboard_android.pro`
5. выбери kit вида:
   - `Android Qt 6.5+ Clang arm64-v8a`

## Сборка APK в Qt Creator

### Debug APK

1. открыть `CarDashboard_android.pro`
2. выбрать Android ARM64 kit
3. `Build`
4. `Run`

Qt Creator сам вызовет `androiddeployqt` и Gradle.

### Release APK

1. выбрать `Release`
2. `Build`
3. `Projects -> Build Android APK`
4. указать keystore для подписи
5. собрать release APK

Типичный результат лежит в каталоге build-дерева, например:

- `build/.../android-build/build/outputs/apk/debug/`
- `build/.../android-build/build/outputs/apk/release/`

## Сборка из консоли

Ниже общий workflow для qmake-проекта. Путь к `qmake.exe` должен быть из Android kit, а не из desktop kit.

```powershell
<QT_ANDROID>\bin\qmake.exe CarDashboard_android.pro
mingw32-make -j8
androiddeployqt --input <build-dir>\android-CarDashboard-deployment-settings.json `
                --output <build-dir>\android-build `
                --android-platform android-34 `
                --gradle
```

Для release-сборки:

```powershell
androiddeployqt --input <build-dir>\android-CarDashboard-deployment-settings.json `
                --output <build-dir>\android-build `
                --android-platform android-34 `
                --gradle `
                --release `
                --sign <keystore-path> <alias>
```

## Подготовка Android LCD дисплея в автомобиле

### 1. Подготовить устройство

- Android 10+ ARM64
- включить Bluetooth
- отключить авто-поворот экрана, если прошивка ведёт себя нестабильно
- при необходимости выдать приложению автостарт после загрузки системы

### 2. Спарить ELM327

- вставить ELM327 в OBD2 разъём
- включить зажигание
- в Android Bluetooth settings выполнить pairing
- убедиться, что адаптер виден как `ELM327`, `OBDII`, `V-LINK`, `iCar` или похожее имя

### 3. Установить APK

```powershell
adb install -r <path-to-apk>
```

### 4. Первый запуск

При первом запуске:

- выдать Bluetooth permissions
- дождаться auto-discovery/auto-connect
- проверить, что в нижней панели кнопка `OBD` стала зелёной

## Режимы работы

### Live OBD2

Если ELM327 подключён:

- `DataModel.canConnected = true`
- симулятор перестаёт перезаписывать live данные
- приборка работает от реальных PID

### Simulator fallback

Если адаптер недоступен:

- приложение остаётся работоспособным
- UI не ломается
- можно использовать встроенный симулятор и тестовые кнопки

## Известные ограничения

### 1. Gear по стандартному OBD2 недоступен

Стандартные PID не дают передачу коробки. Для реального gear-индикатора нужен:

- отдельный CAN/UDS источник
- либо vendor-specific PID
- либо отдельный вход от TCU/ECU

### 2. Не все ELM327 одинаково качественные

Некоторые дешёвые клоны:

- нестабильно отвечают на `0142`
- имеют высокий latency
- отваливаются при агрессивном polling

Если адаптер слабый, увеличь `CAR_DASHBOARD_ELM327_POLL_MS` до `150-200`.

### 3. UI пока намеренно не пересчитан под конкретную матрицу

Сейчас задача решена как перенос существующего 4K UI на Android без редизайна.
Тонкая адаптация под конкретное LCD разрешение может быть сделана отдельным этапом.
