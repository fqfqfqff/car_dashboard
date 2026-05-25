# CarDashboard — Приборная панель
Qt 6.5+ | QML | C++ | QPainter | macOS

---

## Структура проекта

```
CarDashboard/
├── CarDashboard.pro
├── resources.qrc
├── main.cpp
├── backend/
│   ├── DataModel.h / .cpp      — Q_PROPERTY модель данных
│   ├── Controller.h / .cpp     — Q_INVOKABLE команды управления
│   └── Simulator.h / .cpp      — QTimer 33ms авто-демо + lerp
├── ui/
│   ├── GaugeItem.h / .cpp      — QQuickPaintedItem (стрелки через QPainter)
│   ├── main.qml                — Window 3840×2160
│   ├── Dashboard.qml           — Компоновка: спидометр / дисплей / тахометр
│   ├── Gauge.qml               — Круговой прибор + sweep-анимация
│   ├── Indicator.qml           — Индикатор с миганием (critical/warning/info)
│   ├── IndicatorPanel.qml      — Панель всех индикаторов
│   ├── Display.qml             — Центральный цифровой дисплей
│   └── ControlsPanel.qml       — Кнопки управления
└── assets/
    ├── fonts/                  — Inter-Regular/Bold/SemiBold.ttf (скачать)
    └── icons/                  — SVG иконки (уже включены)
```

---

## Установка шрифтов

1. Перейди на https://fonts.google.com/specimen/Inter
2. Скачай: Inter Regular (400), SemiBold (600), Bold (700)
3. Переименуй файлы точно так:
   - `Inter-Regular.ttf`
   - `Inter-SemiBold.ttf`
   - `Inter-Bold.ttf`
4. Положи в папку `assets/fonts/`

---

## Сборка в Qt Creator

1. Открой `CarDashboard.pro` → File → Open File or Project
2. Configure: выбери **Desktop Qt 6.5 (или выше) for macOS**
3. Нажми **Run** (Cmd+R)

---

## Возможные проблемы

### Шрифт не отображается
- Убедись что .ttf файлы лежат в `assets/fonts/` с точными именами
- Файлы должны быть прописаны в `resources.qrc`

### Ошибка компиляции QQuickPaintedItem
- Убедись что в .pro стоит: `QT += quick qml gui svg`

### macOS: предупреждение об архитектуре
- В .pro уже прописано: `QMAKE_APPLE_DEVICE_ARCHS = arm64`
- Если у тебя Intel Mac — замени на `x86_64`

### SVG иконки не отображаются
- Убедись что в .pro есть: `QT += svg`

---

## Демо-режим

Симулятор автоматически проигрывает 6 фаз по 5 секунд:
- Холостые → Городская езда → Трасса → Спортивный режим → Торможение → Стоп

При запуске: sweep-анимация стрелок (0 → макс → 0 → текущее значение)

---

## Расширение под CAN-шину

Замени `Simulator::tick()` на чтение с CAN:
```cpp
// Вместо авто-демо фаз:
m_model->setSpeed(canBus->read(CAN_ID_SPEED));
m_model->setRpm(canBus->read(CAN_ID_RPM));
// и т.д.
```
