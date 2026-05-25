#!/usr/bin/env python3
"""
can_test_sender.py
──────────────────
Реалистичный тестовый отправщик CAN-фреймов через Kvaser.
Физика: инерция, передаточные числа, прогрев двигателя, расход топлива.

Установка:
    pip install canlib

Использование:
    python can_test_sender.py [--channel 1] [--bitrate 500000] [--scenario full]

Сценарии:
    full      — полный тест: прогрев → езда → индикаторы (по умолчанию)
    driving   — бесконечная езда с реалистичной физикой
    idle      — холостой ход
    indicators — тест всех индикаторов
"""

import argparse
import time
import math
import sys

try:
    from canlib import canlib, Frame
except ImportError:
    print("ERROR: canlib не установлен. Выполни: pip install canlib")
    sys.exit(1)

# ─── CAN ID ───────────────────────────────────────────────────────────────────
CAN_ID_SPEED       = 0x0B0
CAN_ID_RPM         = 0x0C0
CAN_ID_ENGINE_TEMP = 0x130
CAN_ID_FUEL_LEVEL  = 0x145
CAN_ID_STATUS_1    = 0x200
CAN_ID_STATUS_2    = 0x201
CAN_ID_GEAR        = 0x210

# STATUS_1 bits
BIT_CHECK_ENGINE = 0x01
BIT_ABS_ACTIVE   = 0x02
BIT_ESP_ACTIVE   = 0x04
BIT_TPMS         = 0x08
BIT_FUEL_LOW     = 0x10
BIT_SEATBELT     = 0x20
BIT_TURN_LEFT    = 0x40
BIT_TURN_RIGHT   = 0x80

# STATUS_2 bits
BIT_OIL_PRESSURE  = 0x01
BIT_OVERHEATING   = 0x02
BIT_BRAKE_SYSTEM  = 0x04
BIT_BATTERY_FAULT = 0x08
BIT_AIRBAG_FAULT  = 0x10
BIT_LOW_BEAM      = 0x20
BIT_HIGH_BEAM     = 0x40
BIT_FOG_LIGHTS    = 0x80

# ─── Физика автомобиля ────────────────────────────────────────────────────────
# Передаточные числа (газ / скорость км/ч для каждой передачи при ~3000 rpm)
GEAR_MAX_SPEED = [0, 30, 60, 95, 130, 165, 200]   # макс скорость на каждой передаче
GEAR_RPM_FACTOR = [0, 110, 65, 42, 31, 24, 20]    # rpm = factor * speed

# Холостые обороты
RPM_IDLE    = 820.0
RPM_MAX     = 6500.0
RPM_SHIFT_UP   = 3200.0   # переключаем вверх
RPM_SHIFT_DOWN = 1200.0   # переключаем вниз

DT = 0.05   # шаг симуляции 50 мс → 20 Гц

# ─── Кодировщики ──────────────────────────────────────────────────────────────

def encode_speed(kmh: float) -> bytes:
    val = max(0, min(0xFFFF, int(kmh / 0.01)))
    return bytes([val >> 8, val & 0xFF, 0, 0, 0, 0, 0, 0])

def encode_rpm(rpm: float) -> bytes:
    val = max(0, min(0xFFFF, int(rpm / 0.25)))
    return bytes([val >> 8, val & 0xFF, 0, 0, 0, 0, 0, 0])

def encode_temp(celsius: float) -> bytes:
    val = max(0, min(255, int(celsius + 40)))
    return bytes([val, 0, 0, 0, 0, 0, 0, 0])

def encode_fuel(percent: float) -> bytes:
    val = max(0, min(100, int(percent)))
    return bytes([val, 0, 0, 0, 0, 0, 0, 0])

def encode_status(bits: int) -> bytes:
    return bytes([bits & 0xFF, 0, 0, 0, 0, 0, 0, 0])

def encode_gear(gear: int) -> bytes:
    return bytes([max(0, min(6, gear)), 0, 0, 0, 0, 0, 0, 0])

def send(ch, can_id: int, data: bytes):
    frame = Frame(id_=can_id, data=data, dlc=8, flags=canlib.MessageFlag.STD)
    ch.write(frame)

def send_all(ch, speed, rpm, temp, fuel, gear, st1, st2):
    send(ch, CAN_ID_SPEED,       encode_speed(speed))
    send(ch, CAN_ID_RPM,         encode_rpm(rpm))
    send(ch, CAN_ID_ENGINE_TEMP, encode_temp(temp))
    send(ch, CAN_ID_FUEL_LEVEL,  encode_fuel(fuel))
    send(ch, CAN_ID_STATUS_1,    encode_status(st1))
    send(ch, CAN_ID_STATUS_2,    encode_status(st2))
    send(ch, CAN_ID_GEAR,        encode_gear(gear))
    time.sleep(0.002)

def sleep_dt():
    time.sleep(DT)

# ─── Физическая модель ────────────────────────────────────────────────────────

class CarPhysics:
    """Простая но реалистичная физика авто."""

    def __init__(self):
        self.speed      = 0.0      # км/ч
        self.rpm        = RPM_IDLE
        self.gear       = 0        # 0 = нейтраль
        self.temp       = 20.0     # °C
        self.fuel       = 78.0     # %
        self.throttle   = 0.0      # 0..1 педаль газа
        self.braking    = False
        self.t          = 0.0
        self._shift_cooldown = 0.0  # задержка между переключениями

    def calc_rpm_for_gear(self, spd, g):
        if g == 0 or spd < 1:
            return RPM_IDLE
        return max(RPM_IDLE, spd * GEAR_RPM_FACTOR[g])

    def update(self):
        self.t += DT
        self._shift_cooldown = max(0, self._shift_cooldown - DT)

        # ── Разгон / торможение ──
        if self.braking:
            # Торможение: замедление ~0.7g = ~25 км/ч за секунду
            self.speed = max(0.0, self.speed - 25.0 * DT)
        else:
            if self.gear > 0 and self.throttle > 0:
                # Разгон слабее на высоких передачах и высокой скорости
                accel = self.throttle * 18.0 / max(1.0, self.gear * 0.8)
                max_spd = GEAR_MAX_SPEED[self.gear]
                if self.speed < max_spd:
                    self.speed += accel * DT
                    self.speed = min(self.speed, max_spd)
            elif self.gear == 0 and self.throttle > 0.05:
                # FIX: газ нажат но передача N — трогаемся (имитация сцепления)
                # машина медленно разгоняется, пока не включится 1-я передача
                self.speed += self.throttle * 4.0 * DT
            elif self.gear == 0:
                # Нет газа, нейтраль — накат/стоп
                self.speed = max(0.0, self.speed - 3.0 * DT)
            else:
                # Есть передача, нет газа — двигатель тормозит
                self.speed = max(0.0, self.speed - 4.0 * DT)

        # ── Автопереключение передач ──
        if self._shift_cooldown <= 0:
            # FIX: speed > 0.5 вместо speed > 2 — машина начинает трогаться сразу
            if self.gear == 0 and self.speed > 0.5 and self.throttle > 0.05:
                self.gear = 1
                self._shift_cooldown = 0.8
            elif self.gear > 0:
                target_rpm = self.calc_rpm_for_gear(self.speed, self.gear)
                # Вверх
                if target_rpm > RPM_SHIFT_UP and self.gear < 6:
                    self.gear += 1
                    self._shift_cooldown = 1.2
                # Вниз
                elif target_rpm < RPM_SHIFT_DOWN and self.gear > 1 and self.speed > 5:
                    self.gear -= 1
                    self._shift_cooldown = 0.8
                # Нейтраль при полной остановке
                elif self.speed < 2 and not self.braking:
                    self.gear = 0

        # ── Обороты ──
        base_rpm = self.calc_rpm_for_gear(self.speed, self.gear)
        if self.gear == 0:
            # Холостые с небольшой пульсацией
            target_rpm = RPM_IDLE + self.throttle * 1500.0
        else:
            target_rpm = base_rpm + self.throttle * 400.0
        # Плавное изменение оборотов (инерция)
        self.rpm += (target_rpm - self.rpm) * 0.25
        self.rpm = max(RPM_IDLE * 0.9, min(RPM_MAX, self.rpm))

        # ── Температура ──
        # Прогрев до рабочей ~90°C, быстрее под нагрузкой
        if self.temp < 90.0:
            warm_rate = 0.03 + self.throttle * 0.05
            self.temp += warm_rate
        else:
            # Небольшие колебания вокруг рабочей
            self.temp = 90.0 + math.sin(self.t * 0.1) * 1.2 + self.throttle * 3.0

        # ── Расход топлива ──
        consumption = DT * (0.0002 + self.throttle * 0.0008 + self.speed * 0.000003)
        self.fuel = max(0.0, self.fuel - consumption)

    @property
    def st1_base(self):
        """Базовые биты STATUS_1 (ремень, фары)."""
        bits = BIT_SEATBELT | BIT_LOW_BEAM
        if self.speed > 90:
            bits |= BIT_HIGH_BEAM
        if self.fuel < 10:
            bits |= BIT_FUEL_LOW
        return bits

# ─── Сценарий: прогрев ────────────────────────────────────────────────────────

def phase_warmup(ch, car):
    """Прогрев ~30 сек: стоим, обороты чуть выше холостых."""
    print("\n[1/4] ПРОГРЕВ — двигатель запускается, прогревается до 60°C...")
    car.temp = 18.0
    car.speed = 0.0
    car.gear  = 0
    car.fuel  = 78.0

    steps = int(30.0 / DT)
    for i in range(steps):
        # Лёгкое нажатие газа при запуске, потом отпускаем
        car.throttle = 0.12 if i < int(5 / DT) else 0.0
        car.braking  = False
        car.update()

        st1 = car.st1_base
        send_all(ch, car.speed, car.rpm, car.temp, car.fuel, car.gear, st1, 0)

        print(f"\r  RPM={car.rpm:5.0f}  Temp={car.temp:4.1f}°C  Fuel={car.fuel:4.1f}%",
              end="", flush=True)
        sleep_dt()

    print(f"\n  → Прогрев завершён. Температура: {car.temp:.1f}°C")

# ─── Сценарий: городская езда ─────────────────────────────────────────────────

def phase_city(ch, car):
    """Городская езда: разгоны до 60, светофоры, повороты."""
    print("\n[2/4] ГОРОД — разгоны/торможения до 60 км/ч...")

    # Последовательность: [газ, торможение, длительность сек]
    script = [
        # Старт со светофора
        (0.85, False, 8.0),   # разгон
        (0.3,  False, 4.0),   # крейсер 50
        (0.0,  True,  3.0),   # торможение — светофор
        (0.0,  False, 2.0),   # стоим

        # Правый поворот — поворотник
        (0.7,  False, 6.0),
        (0.2,  False, 3.0),
        (0.0,  True,  2.5),
        (0.0,  False, 1.5),

        # Снова разгон
        (0.9,  False, 7.0),
        (0.35, False, 5.0),
        (0.0,  True,  3.5),
        (0.0,  False, 2.0),
    ]

    turn_right_phases = {2, 3}   # фазы с поворотником вправо
    turn_left_phases  = {6, 7}

    for phase_idx, (throttle, braking, duration) in enumerate(script):
        steps = int(duration / DT)
        for i in range(steps):
            car.throttle = throttle
            car.braking  = braking
            car.update()

            st1 = car.st1_base
            if phase_idx in turn_right_phases:
                st1 |= BIT_TURN_RIGHT
            if phase_idx in turn_left_phases:
                st1 |= BIT_TURN_LEFT

            # ABS при резком торможении на скорости
            st2 = 0
            if braking and car.speed > 40 and i < int(1.0 / DT):
                st2 |= BIT_ABS_ACTIVE

            send_all(ch, car.speed, car.rpm, car.temp, car.fuel,
                     car.gear, st1, st2)

            print(f"\r  {car.speed:5.1f} км/ч  RPM={car.rpm:5.0f}  "
                  f"Передача={car.gear}  Temp={car.temp:.1f}°C  Fuel={car.fuel:.1f}%  ",
                  end="", flush=True)
            sleep_dt()

    print(f"\n  → Город завершён.")

# ─── Сценарий: трасса ─────────────────────────────────────────────────────────

def phase_highway(ch, car):
    """Трасса: разгон до 140, обгон, торможение."""
    print("\n[3/4] ТРАССА — разгон до 140 км/ч, обгон...")

    script = [
        # Выезд на трассу
        (1.0,  False, 12.0),  # полный газ — разгон
        (0.5,  False,  8.0),  # крейсер ~120
        # Обгон
        (0.95, False,  6.0),  # разгон для обгона
        (0.45, False,  5.0),  # крейсер ~140
        # Сброс
        (0.15, False,  4.0),
        (0.0,  True,   5.0),  # торможение перед съездом
        (0.3,  False,  3.0),
        (0.0,  True,   4.0),  # до ~60
        (0.2,  False,  2.0),
        (0.0,  True,   3.0),  # остановка
        (0.0,  False,  1.5),
    ]

    turn_left_phases = {2, 3}  # обгон — поворотник влево

    for phase_idx, (throttle, braking, duration) in enumerate(script):
        steps = int(duration / DT)
        for i in range(steps):
            car.throttle = throttle
            car.braking  = braking
            car.update()

            st1 = car.st1_base
            if phase_idx in turn_left_phases:
                st1 |= BIT_TURN_LEFT

            st2 = 0
            # ESP при резком манёвре
            if phase_idx == 2 and i < int(1.5 / DT):
                st2 |= BIT_ESP_ACTIVE

            send_all(ch, car.speed, car.rpm, car.temp, car.fuel,
                     car.gear, st1, st2)

            print(f"\r  {car.speed:5.1f} км/ч  RPM={car.rpm:5.0f}  "
                  f"Передача={car.gear}  Temp={car.temp:.1f}°C  Fuel={car.fuel:.1f}%  ",
                  end="", flush=True)
            sleep_dt()

    print(f"\n  → Трасса завершена.")

# ─── Сценарий: тест индикаторов ───────────────────────────────────────────────

def phase_indicators(ch, car):
    """
    Тест индикаторов: машина стоит, двигатель работает.
    1) Каждый индикатор плавно «появляется» (держится 2 сек) и гаснет (1 сек пауза)
    2) Все индикаторы загораются по одному с накоплением
    3) Все вместе горят 3 сек
    4) Все гаснут
    """
    print("\n[4/4] ТЕСТ ИНДИКАТОРОВ...")

    car.speed    = 0.0
    car.gear     = 0
    car.throttle = 0.0
    car.braking  = False

    # Базовая отправка (фон)
    def send_base(st1_extra=0, st2_extra=0):
        car.update()
        send_all(ch, 0, car.rpm, car.temp, car.fuel, 0,
                 BIT_SEATBELT | st1_extra, st2_extra)

    # Все индикаторы: (байт, регистр 1 или 2, название)
    all_indicators = [
        (BIT_CHECK_ENGINE, 1, "CHECK ENGINE"),
        (BIT_ABS_ACTIVE,   1, "ABS"),
        (BIT_ESP_ACTIVE,   1, "ESP"),
        (BIT_TPMS,         1, "TPMS"),
        (BIT_FUEL_LOW,     1, "FUEL LOW"),
        (BIT_TURN_LEFT,    1, "TURN LEFT"),
        (BIT_TURN_RIGHT,   1, "TURN RIGHT"),
        (BIT_OIL_PRESSURE,  2, "OIL PRESSURE"),
        (BIT_OVERHEATING,   2, "OVERHEATING"),
        (BIT_BRAKE_SYSTEM,  2, "BRAKE SYSTEM"),
        (BIT_BATTERY_FAULT, 2, "BATTERY FAULT"),
        (BIT_AIRBAG_FAULT,  2, "AIRBAG FAULT"),
        (BIT_LOW_BEAM,      2, "LOW BEAM"),
        (BIT_HIGH_BEAM,     2, "HIGH BEAM"),
        (BIT_FOG_LIGHTS,    2, "FOG LIGHTS"),
    ]

    # ── Фаза А: по одному, 2 сек горит, 1 сек пауза ──
    print("  Фаза A: каждый индикатор по очереди...")
    for bit, reg, name in all_indicators:
        print(f"    → {name}", end="", flush=True)

        on_steps  = int(2.0 / DT)
        off_steps = int(1.0 / DT)

        for _ in range(on_steps):
            if reg == 1:
                send_base(st1_extra=bit)
            else:
                car.update()
                send_all(ch, 0, car.rpm, car.temp, car.fuel, 0,
                         BIT_SEATBELT, bit)
            sleep_dt()

        # Пауза — всё выключено
        for _ in range(off_steps):
            send_base()
            sleep_dt()

        print(" ✓")

    # ── Небольшая пауза перед фазой Б ──
    print("  Пауза 2 сек...")
    for _ in range(int(2.0 / DT)):
        send_base()
        sleep_dt()

    # ── Фаза Б: накопительное включение ──
    print("  Фаза Б: индикаторы загораются один за одним и остаются...")
    active_st1 = BIT_SEATBELT
    active_st2 = 0

    for bit, reg, name in all_indicators:
        print(f"    + {name}")

        if reg == 1:
            active_st1 |= bit
        else:
            active_st2 |= bit

        steps = int(0.8 / DT)  # каждый добавляется с паузой 0.8 сек
        for _ in range(steps):
            car.update()
            send_all(ch, 0, car.rpm, car.temp, car.fuel, 0,
                     active_st1, active_st2)
            sleep_dt()

    # ── Все горят 3 сек ──
    print("  Все индикаторы горят...")
    for _ in range(int(3.0 / DT)):
        car.update()
        send_all(ch, 0, car.rpm, car.temp, car.fuel, 0,
                 active_st1, active_st2)
        sleep_dt()

    # ── Плавное погашение: гасим один за одним с паузой ──
    print("  Гасим один за одним...")
    for bit, reg, name in reversed(all_indicators):
        print(f"    - {name}")

        if reg == 1:
            active_st1 &= ~bit
        else:
            active_st2 &= ~bit

        steps = int(0.5 / DT)
        for _ in range(steps):
            car.update()
            send_all(ch, 0, car.rpm, car.temp, car.fuel, 0,
                     active_st1, active_st2)
            sleep_dt()

    # Финальная пауза — тишина
    print("  Всё погашено.")
    for _ in range(int(2.0 / DT)):
        send_base()
        sleep_dt()

# ─── Бесконечная езда (standalone) ───────────────────────────────────────────

def scenario_driving_loop(ch):
    """Бесконечный цикл городской + трассовой езды."""
    print("Сценарий: DRIVING (Ctrl+C для остановки)")
    car = CarPhysics()
    phase_warmup(ch, car)
    while True:
        phase_city(ch, car)
        phase_highway(ch, car)

def scenario_idle_loop(ch):
    """Холостой ход бесконечно."""
    print("Сценарий: IDLE (Ctrl+C для остановки)")
    car = CarPhysics()
    car.temp = 20.0
    t = 0.0
    while True:
        car.throttle = 0.0
        car.braking  = False
        car.update()
        send_all(ch, 0, car.rpm, car.temp, car.fuel, 0, BIT_SEATBELT, 0)
        print(f"\r  RPM={car.rpm:5.0f}  Temp={car.temp:4.1f}°C  Fuel={car.fuel:.1f}%  ",
              end="", flush=True)
        sleep_dt()

def scenario_indicators_only(ch):
    """Только тест индикаторов."""
    car = CarPhysics()
    car.temp = 90.0
    car.fuel = 50.0
    phase_indicators(ch, car)

def scenario_full(ch):
    """Полный тест: прогрев → город → трасса → индикаторы."""
    print("Сценарий: FULL — полный тест")
    car = CarPhysics()
    phase_warmup(ch, car)
    phase_city(ch, car)
    phase_highway(ch, car)
    phase_indicators(ch, car)
    print("\n✅ Полный тест завершён.")

# ─── main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Kvaser CAN Test Sender")
    parser.add_argument("--channel",  type=int, default=1,
                        help="Kvaser channel index (default: 1)")
    parser.add_argument("--bitrate",  type=int, default=500000,
                        help="CAN bitrate bps (default: 500000)")
    parser.add_argument("--scenario",
                        choices=["full", "driving", "idle", "indicators"],
                        default="full",
                        help="Сценарий: full / driving / idle / indicators (default: full)")
    args = parser.parse_args()

    print(f"Подключение: канал={args.channel}, битрейт={args.bitrate} bps")
    print(f"Сценарий: {args.scenario}\n")

    try:
        ch = canlib.openChannel(
            channel=args.channel,
            flags=canlib.Open.ACCEPT_VIRTUAL
        )
        ch.setBusParams(args.bitrate)
        ch.busOn()
    except Exception as e:
        print(f"ERROR: не удалось открыть канал: {e}")
        print("Убедись, что Kvaser подключён и драйверы установлены.")
        sys.exit(1)

    print(f"CAN канал {args.channel} открыт.\n")
    print(">>> Нажми ENTER чтобы запустить двигатель...")
    input()
    print("Запускаем...\n")

    try:
        if args.scenario == "full":
            scenario_full(ch)
        elif args.scenario == "driving":
            scenario_driving_loop(ch)
        elif args.scenario == "idle":
            scenario_idle_loop(ch)
        elif args.scenario == "indicators":
            scenario_indicators_only(ch)
    except KeyboardInterrupt:
        print("\n\nОстановлено.")
    finally:
        ch.busOff()
        ch.close()
        print("Канал закрыт.")

if __name__ == "__main__":
    main()