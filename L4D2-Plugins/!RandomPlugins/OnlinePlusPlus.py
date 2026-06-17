# pip install python-a2s

import os
import time
import subprocess
import a2s

# =========================
# НАСТРОЙКИ
# =========================
IP = "83.246.186.7"
PORTS = [27001, 27002, 27003, 27007]

STEAM_EXE = r"C:\Program Files (x86)\Steam\steam.exe"

CHECK_EVERY_SCAN = 2
CHECK_EVERY_WATCH = 60

JOIN_IF_PLAYERS_BELOW = 4      # Заходим, если игроков меньше 4
LEAVE_IF_PLAYERS_AT_LEAST = 5  # Выходим, когда стало 5 или больше

# Ищем бота НЕ по точному совпадению, а по наличию подстроки в нике.
# Примеры: DemasturBOT, AliceBOT
BOT_NAME_PATTERNS = [
    "bot",
]

BOT_MAX_TIME_SECONDS = 20 * 60      # 20 минут
BOT_RECONNECT_DELAY_SECONDS = 60    # переподключение через 1 минуту

BASE_STEAM_ARGS = [
    "-applaunch", "550",
    "-novid",
    "-lv",
    "+fps_max", "30",
    "-windowed",
    "-w", "640",
    "-h", "480",
]


def is_process_running(name: str) -> bool:
    try:
        out = subprocess.check_output(
            ["tasklist", "/FI", f"IMAGENAME eq {name}"],
            text=True,
            encoding="cp866",
            errors="ignore",
        )
        return name.lower() in out.lower()
    except Exception:
        try:
            out = subprocess.check_output(
                ["tasklist", "/FI", f"IMAGENAME eq {name}"],
                text=True,
                errors="ignore",
            )
            return name.lower() in out.lower()
        except Exception:
            return False


def close_l4d2() -> None:
    subprocess.run(
        ["taskkill", "/IM", "left4dead2.exe", "/F"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def launch_l4d2(ip: str, port: int) -> None:
    if not os.path.isfile(STEAM_EXE):
        raise FileNotFoundError(f"steam.exe not found: {STEAM_EXE}")

    args = BASE_STEAM_ARGS + ["+connect", f"{ip}:{port}"]

    subprocess.Popen(
        [STEAM_EXE] + args,
        creationflags=subprocess.CREATE_NEW_PROCESS_GROUP,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def get_players_count(ip: str, port: int) -> int:
    info = a2s.info((ip, port), timeout=5.0)
    return info.player_count


def get_players(ip: str, port: int):
    return a2s.players((ip, port), timeout=5.0)


def is_bot_name(name: str, patterns: list[str]) -> bool:
    """
    Возвращает True, если ник игрока содержит любой из шаблонов.
    Например:
      patterns = ["bot"]
      DemasturBOT -> True
      AliceBOT    -> True
      Player123   -> False
    """
    name_lower = (name or "").strip().lower()
    for pattern in patterns:
        if pattern.strip().lower() in name_lower:
            return True
    return False


def find_bot_on_server(ip: str, port: int, bot_patterns: list[str]):
    """
    Ищет бота по частичному совпадению ника.
    Возвращает dict:
    {
        "name": str,
        "duration": float,
        "score": int
    }

    Если бот не найден -> None
    Если найдено больше одного бота -> Exception
    """
    players = get_players(ip, port)

    found = []

    for p in players:
        player_name = (p.name or "").strip()
        if is_bot_name(player_name, bot_patterns):
            found.append({
                "name": player_name,
                "duration": float(p.duration),
                "score": getattr(p, "score", 0),
            })

    if len(found) == 0:
        return None

    if len(found) > 1:
        raise RuntimeError(
            f"На сервере {port} найдено больше одного бота: "
            + ", ".join(f['name'] for f in found)
        )

    return found[0]


def count_humans_without_bot(ip: str, port: int, bot_patterns: list[str]) -> int:
    """
    Считает игроков на сервере, кроме бота.
    Если найден один бот, он исключается из подсчёта.
    Если бот не найден, возвращается общее количество игроков.
    Если найдено больше одного бота, кидает исключение.
    """
    players = get_players(ip, port)

    bot_count = 0
    others_count = 0

    for p in players:
        player_name = (p.name or "").strip()
        if is_bot_name(player_name, bot_patterns):
            bot_count += 1
        else:
            others_count += 1

    if bot_count > 1:
        raise RuntimeError(f"На сервере {port} найдено больше одного бота.")

    return others_count


def main():
    print("Checking running L4D2 processes...")

    if is_process_running("left4dead2.exe"):
        print("Closing running L4D2...")
        close_l4d2()
        time.sleep(2)

    mode = "scan"
    idx = 0
    watch_idx = None

    while True:
        try:
            # ======================
            # SCAN
            # ======================
            if mode == "scan":
                port = PORTS[idx]
                players_count = get_players_count(IP, port)

                print(f"[{time.strftime('%H:%M:%S')}] SCAN  port={port} players={players_count}")

                # Если игроков уже достаточно — идем к следующему серверу
                if players_count >= JOIN_IF_PLAYERS_BELOW:
                    idx = (idx + 1) % len(PORTS)
                    time.sleep(CHECK_EVERY_SCAN)
                    continue

                # Если игроков меньше порога — заходим на сервер
                if not is_process_running("left4dead2.exe"):
                    print(f"> Server {port} has less than {JOIN_IF_PLAYERS_BELOW} players. Connecting...")
                    launch_l4d2(IP, port)
                else:
                    print(f"> L4D2 already running. Switching to WATCH on port {port}.")

                watch_idx = idx
                mode = "watch"
                time.sleep(CHECK_EVERY_WATCH)
                continue

            # ======================
            # WATCH
            # ======================
            port = PORTS[watch_idx]

            if not is_process_running("left4dead2.exe"):
                print(f"[{time.strftime('%H:%M:%S')}] WATCH port={port} game is not running. Returning to SCAN.")
                mode = "scan"
                idx = watch_idx
                watch_idx = None
                time.sleep(CHECK_EVERY_SCAN)
                continue

            players_count = get_players_count(IP, port)
            print(f"[{time.strftime('%H:%M:%S')}] WATCH port={port} players={players_count}")

            # Ищем бота по шаблону ника
            try:
                bot = find_bot_on_server(IP, port, BOT_NAME_PATTERNS)
            except Exception as e:
                print(f"[{time.strftime('%H:%M:%S')}] WATCH port={port} bot-check error: {e}")
                bot = None

            if bot is not None:
                bot_minutes = bot["duration"] / 60
                print(
                    f"[{time.strftime('%H:%M:%S')}] BOT FOUND "
                    f"port={port} name={bot['name']} time={bot['duration']:.0f}s ({bot_minutes:.1f} min)"
                )

                # Считаем, есть ли кто-то кроме бота
                try:
                    others_count = count_humans_without_bot(IP, port, BOT_NAME_PATTERNS)
                except Exception as e:
                    print(f"[{time.strftime('%H:%M:%S')}] WATCH port={port} player-count-without-bot error: {e}")
                    others_count = None

                if others_count is not None:
                    print(
                        f"[{time.strftime('%H:%M:%S')}] WATCH port={port} "
                        f"players_except_bot={others_count}"
                    )

                    # Бот выходит ТОЛЬКО если:
                    # 1) сидит больше 20 минут
                    # 2) кроме него на сервере никого нет
                    if bot["duration"] > BOT_MAX_TIME_SECONDS and others_count == 0:
                        print(
                            f"[{time.strftime('%H:%M:%S')}] BOT {bot['name']} has been alone on server "
                            f"for more than 20 minutes. Reconnecting in 60 seconds..."
                        )

                        if is_process_running("left4dead2.exe"):
                            close_l4d2()

                        time.sleep(BOT_RECONNECT_DELAY_SECONDS)

                        print(f"[{time.strftime('%H:%M:%S')}] Reconnecting bot to port={port}...")
                        launch_l4d2(IP, port)

                        time.sleep(CHECK_EVERY_WATCH)
                        continue
            else:
                print(f"[{time.strftime('%H:%M:%S')}] WATCH port={port} bot not found on server.")

            # Если сервер пустой — закрываем игру и начинаем сканирование заново
            if players_count == 0:
                print("WATCH: players=0. Closing game and restarting scan from first server.")

                if is_process_running("left4dead2.exe"):
                    close_l4d2()

                mode = "scan"
                idx = 0
                watch_idx = None
                time.sleep(CHECK_EVERY_SCAN)
                continue

            # Если игроков стало 5 или больше — закрываем игру и продолжаем скан дальше
            if players_count >= LEAVE_IF_PLAYERS_AT_LEAST:
                print(f"WATCH: players reached {players_count}. Closing game and resuming scan.")

                if is_process_running("left4dead2.exe"):
                    close_l4d2()

                idx = (watch_idx + 1) % len(PORTS)
                watch_idx = None
                mode = "scan"
                time.sleep(CHECK_EVERY_SCAN)
                continue

            time.sleep(CHECK_EVERY_WATCH)

        except Exception as e:
            print(f"[{time.strftime('%H:%M:%S')}] ERROR: {e}")
            time.sleep(5)


if __name__ == "__main__":
    main()