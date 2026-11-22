"""Собирает пиксельные спрайты 16×16 и короткие звуки GameTomb."""

import math
import struct
import wave
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPRITE_DIR = ROOT / "assets" / "sprites"
SFX_DIR = ROOT / "assets" / "sfx"

TRANS = (0, 0, 0, 0)
OUT = (8, 6, 16, 255)
HOOD = (72, 36, 120, 255)
PINK = (255, 70, 168, 255)
VISOR = (40, 220, 255, 255)
VISOR_H = (210, 255, 255, 255)
FACE = (6, 4, 12, 255)
JACKET = (48, 26, 88, 255)
JACKET_D = (28, 14, 52, 255)
PIPE = (32, 168, 176, 255)
PIPE_B = (24, 148, 162, 255)
CYAN = (120, 245, 255, 255)
CYAN_D = (20, 90, 110, 255)
GOLD = (255, 196, 48, 255)
GOLD_L = (255, 236, 160, 255)
GOLD_D = (196, 120, 16, 255)
MAGENTA = (255, 48, 168, 255)
MAGENTA_D = (110, 12, 70, 255)
PURPLE = (64, 12, 84, 255)
WHITE = (245, 250, 255, 255)
SPIKE_BG = (6, 18, 28, 255)


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: Path, width: int, height: int, rows: list[bytes]) -> None:
    raw = b"".join(b"\x00" + row for row in rows)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


def rows_from(pixels: list[list[tuple[int, int, int, int]]]) -> list[bytes]:
    return [b"".join(bytes(px) for px in row) for row in pixels]


def blank(w: int, h: int, color: tuple[int, int, int, int]) -> list[list[tuple[int, int, int, int]]]:
    return [[color for _ in range(w)] for _ in range(h)]


def setp(buf, x: int, y: int, color) -> None:
    if 0 <= x < len(buf[0]) and 0 <= y < len(buf):
        buf[y][x] = color


def fill_ellipse(buf, cx: float, cy: float, rx: float, ry: float, color) -> None:
    h = len(buf)
    w = len(buf[0])
    for y in range(h):
        for x in range(w):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                setp(buf, x, y, color)


def fill_rect(buf, x0: int, y0: int, x1: int, y1: int, color) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            setp(buf, x, y, color)


def add_outline(buf) -> None:
    h = len(buf)
    w = len(buf[0])
    extra: list[tuple[int, int]] = []
    for y in range(h):
        for x in range(w):
            if buf[y][x][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and buf[ny][nx][3] != 0:
                    extra.append((x, y))
                    break
    for x, y in extra:
        buf[y][x] = OUT


def rot90(buf):
    size = len(buf)
    out = blank(size, size, TRANS)
    for y in range(size):
        for x in range(size):
            out[x][size - 1 - y] = buf[y][x]
    return out


def make_player():
    buf = blank(16, 16, TRANS)
    fill_rect(buf, 0, 0, 15, 15, JACKET)
    fill_rect(buf, 1, 0, 14, 5, HOOD)
    fill_rect(buf, 2, 2, 13, 5, VISOR_H)
    setp(buf, 2, 2, VISOR)
    setp(buf, 13, 2, VISOR)
    fill_rect(buf, 0, 6, 1, 12, PINK)
    fill_rect(buf, 14, 6, 15, 12, PINK)
    fill_rect(buf, 6, 7, 9, 10, JACKET_D)
    fill_rect(buf, 2, 13, 6, 15, PINK)
    fill_rect(buf, 9, 13, 13, 15, PINK)
    return buf


def make_floor(variant: int):
    color = PIPE if variant == 0 else PIPE_B
    buf = blank(12, 12, color)
    highlight = (78, 214, 214, 255) if variant == 0 else (64, 196, 200, 255)
    for i in range(2, 10):
        buf[5][i] = highlight
        buf[6][i] = highlight
    return buf


def make_coin():
    buf = blank(12, 12, TRANS)
    for y in range(12):
        for x in range(12):
            dx = abs(x + 0.5 - 6)
            dy = abs(y + 0.5 - 5) * 0.85
            if dx + dy < 3.3:
                if x < 5:
                    buf[y][x] = GOLD_D
                elif y < 5:
                    buf[y][x] = GOLD_L
                else:
                    buf[y][x] = GOLD
            elif 8 <= y <= 10 and dx < (10 - y) * 0.8 + 1:
                buf[y][x] = PINK
    setp(buf, 2, 3, GOLD_L)
    setp(buf, 9, 2, GOLD_L)
    add_outline(buf)
    return buf


def make_lava(frame: int, top: bool):
    buf = blank(16, 16, MAGENTA_D)
    for y in range(16):
        for x in range(16):
            yy = (y + frame * 4) % 16
            column = (x + frame * 2) % 6
            if column in (1, 2):
                color = PINK if (yy % 5) < 2 else MAGENTA
            else:
                color = MAGENTA_D if (yy % 4) < 2 else PURPLE
            if (x * 3 + y * 5 + frame) % 11 == 0:
                color = CYAN
            if top and y <= 2:
                color = WHITE if (x + frame) % 2 == 0 else PINK
            buf[y][x] = color
    return buf


def make_spike():
    buf = blank(12, 12, SPIKE_BG)
    for tip_x in (2, 6, 10):
        for dy in range(8):
            y = 1 + dy
            half = dy // 2
            color = CYAN if dy < 3 else CYAN_D
            for x in range(tip_x - half, tip_x + half + 1):
                setp(buf, x, y, color)
    return buf


def scale(buf, factor: int):
    h = len(buf)
    w = len(buf[0])
    out = blank(w * factor, h * factor, TRANS)
    for y in range(h):
        for x in range(w):
            color = buf[y][x]
            for dy in range(factor):
                for dx in range(factor):
                    out[y * factor + dy][x * factor + dx] = color
    return out


def save(name: str, buf) -> None:
    write_png(SPRITE_DIR / name, len(buf[0]), len(buf), rows_from(buf))


def preview(parts) -> None:
    scale_n = 6
    gap = 8
    max_h = max(len(buf) for _, buf in parts) * scale_n
    width = gap + sum(len(buf[0]) * scale_n + gap for _, buf in parts)
    sheet = blank(width, max_h + gap * 2, (5, 4, 12, 255))
    cursor = gap
    for _, buf in parts:
        scaled = scale(buf, scale_n)
        for y, row in enumerate(scaled):
            for x, color in enumerate(row):
                if color[3] == 0:
                    continue
                sheet[gap + y][cursor + x] = color
        cursor += len(buf[0]) * scale_n + gap
    write_png(SPRITE_DIR / "preview.png", len(sheet[0]), len(sheet), rows_from(sheet))


def beep(path: Path, segments: list[tuple[float, float, float]]) -> None:
    rate = 22050
    frames = bytearray()
    for freq, dur, vol in segments:
        count = int(rate * dur)
        for i in range(count):
            t = i / rate
            env = 1.0 - (i / count)
            wave_v = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
            sample = int(max(-1.0, min(1.0, wave_v * vol * env)) * 32767)
            frames += struct.pack("<h", sample)
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(rate)
        handle.writeframes(frames)


def noise_sweep(path: Path) -> None:
    rate = 22050
    dur = 0.38
    count = int(rate * dur)
    frames = bytearray()
    state = 1
    for i in range(count):
        t = i / count
        state = (1103515245 * state + 12345) & 0x7FFFFFFF
        noise = (state / 0x7FFFFFFF) * 2.0 - 1.0
        freq = 420 - 340 * t
        sq = 1.0 if math.sin(2 * math.pi * freq * (i / rate)) >= 0 else -1.0
        env = (1.0 - t) ** 1.4
        sample = int(max(-1.0, min(1.0, (sq * 0.55 + noise * 0.45) * 0.42 * env)) * 32767)
        frames += struct.pack("<h", sample)
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(rate)
        handle.writeframes(frames)


def main() -> None:
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    SFX_DIR.mkdir(parents=True, exist_ok=True)
    player = make_player()
    floor = make_floor(0)
    floor_b = make_floor(1)
    coin = make_coin()
    lava = make_lava(0, False)
    lava_b = make_lava(1, False)
    lava_top = make_lava(0, True)
    lava_top_b = make_lava(1, True)
    spike = make_spike()
    save("player.png", player)
    save("floor.png", floor)
    save("floor_b.png", floor_b)
    save("coin.png", coin)
    save("lava.png", lava)
    save("lava_b.png", lava_b)
    save("lava_top.png", lava_top)
    save("lava_top_b.png", lava_top_b)
    save("spike_n.png", spike)
    save("spike_e.png", rot90(spike))
    save("spike_s.png", rot90(rot90(spike)))
    save("spike_w.png", rot90(rot90(rot90(spike))))
    preview([
        ("player", player),
        ("floor", floor),
        ("coin", coin),
        ("spike", spike),
        ("lava", lava_top),
    ])
    beep(SFX_DIR / "coin.wav", [(880, 0.05, 0.28), (1320, 0.08, 0.24)])
    beep(SFX_DIR / "bump.wav", [(150, 0.04, 0.22)])
    noise_sweep(SFX_DIR / "die.wav")
    print("assets ready")


if __name__ == "__main__":
    main()
