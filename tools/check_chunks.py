"""Проверка чанков: дэш до стены, шип убивает только в остриё."""
from __future__ import annotations

W = 13
GATE = {5, 6, 7}
DIRS = [(0, -1), (1, 0), (0, 1), (-1, 0)]
SPIKE = {"^": (0, -1), "v": (0, 1), "<": (-1, 0), ">": (1, 0)}
SHOOT = set("UDLR")


def parse(rows: list[str]) -> tuple[dict, dict, set, set]:
    floors: dict[tuple[int, int], str] = {}
    spikes: dict[tuple[int, int], tuple[int, int]] = {}
    entry: set[tuple[int, int]] = set()
    exit_: set[tuple[int, int]] = set()
    h = len(rows)
    for y, row in enumerate(rows):
        if len(row) != W:
            raise SystemExit(f"width {len(row)} at row {y}: {row}")
        for x, ch in enumerate(row):
            if ch in ".t*":
                floors[(x, y)] = ch
            elif ch in SPIKE:
                spikes[(x, y)] = SPIKE[ch]
            elif ch in SHOOT or ch == "#":
                pass
            else:
                raise SystemExit(f"bad char {ch!r} at {x},{y}")
        if y == 0:
            exit_ = {(x, y) for x in GATE if (x, y) in floors}
        if y == h - 1:
            entry = {(x, y) for x in GATE if (x, y) in floors}
    return floors, spikes, entry, exit_


def kills(spikes, cell, move) -> bool:
    danger = spikes.get(cell)
    if not danger:
        return False
    return move[0] * danger[0] + move[1] * danger[1] < -0.7


def slide(floors, spikes, start, direction):
    x, y = start
    dx, dy = direction
    nxt = (x + dx, y + dy)
    if kills(spikes, nxt, direction) or nxt not in floors:
        return []
    cells = []
    pos = start
    for _ in range(80):
        nxt = (pos[0] + dx, pos[1] + dy)
        if kills(spikes, nxt, direction):
            return []
        if nxt not in floors:
            return cells
        pos = nxt
        cells.append(pos)
    return []


def covers(rows: list[str]) -> list[tuple[int, int]]:
    floors, spikes, entry, exit_ = parse(rows)
    if not entry or not exit_:
        return [(-1, -1)]
    seen = set(entry)
    stops = set(entry)
    queue = list(entry)
    while queue:
        pos = queue.pop(0)
        for direction in DIRS:
            cells = slide(floors, spikes, pos, direction)
            if not cells:
                continue
            seen.update(cells)
            stop = cells[-1]
            if stop not in stops:
                stops.add(stop)
                queue.append(stop)
    missing = [c for c in floors if c not in seen]
    return missing


def show(rows: list[str]) -> None:
    floors, spikes, entry, exit_ = parse(rows)
    seen = set(entry)
    stops = set(entry)
    queue = list(entry)
    while queue:
        pos = queue.pop(0)
        for direction in DIRS:
            cells = slide(floors, spikes, pos, direction)
            if not cells:
                continue
            seen.update(cells)
            stop = cells[-1]
            if stop not in stops:
                stops.add(stop)
                queue.append(stop)
    for y, row in enumerate(rows):
        line = []
        for x, ch in enumerate(row):
            if (x, y) in floors and (x, y) not in seen:
                line.append("?")
            elif (x, y) in stops and ch == ".":
                line.append("S")
            else:
                line.append(ch)
        print(f"{y:02d} {''.join(line)}")


def blank(h: int) -> list[list[str]]:
    rows = [["#"] * W for _ in range(h)]
    for y in (0, h - 1):
        for x in GATE:
            rows[y][x] = "."
    return rows


def paint(rows: list[list[str]], y: int, xs: range, ch: str = ".") -> None:
    for x in xs:
        rows[y][x] = ch


def slide_ok(rows: list[str], start: tuple[int, int], direction: tuple[int, int], length: int) -> bool:
    floors, spikes, _entry, _exit = parse(rows)
    cells = slide(floors, spikes, start, direction)
    return len(cells) == length and cells[-1] == (start[0] + direction[0] * length, start[1] + direction[1] * length)


def carve_run(g: list[list[str]], start: tuple[int, int], direction: tuple[int, int], length: int) -> tuple[int, int]:
    x, y = start
    dx, dy = direction
    for i in range(1, length + 1):
        g[y + dy * i][x + dx * i] = "."
    return (x + dx * length, y + dy * length)


def build_r() -> list[str]:
    h = 16
    g = blank(h)
    # Entry climbs onto a full antechamber; x=6/7 above the gate stay walls, so the dash stops.
    for x in range(1, 12):
        g[14][x] = "."
    # Left hall. Ceiling is 5 wide. A wall mass forces the return dash to stop.
    for y in range(10, 14):
        g[y][1] = "."
    for x in range(2, 6):
        g[10][x] = "."
    for y in (11, 12):
        g[y][5] = "."
    g[12][4] = "."
    g[12][3] = "."
    g[13][3] = "."
    # From the left hall into the center, then up. x=7 on this row stays wall so the dash stops.
    g[9][5] = "."
    g[9][6] = "."
    for y in range(5, 10):
        g[y][6] = "."
    # Upper loop: the center shaft stops, the run goes out to the left wall and back on column 5.
    for x in range(1, 6):
        g[5][x] = "."
    for y in (2, 3, 4):
        g[y][1] = "."
    for x in range(2, 6):
        g[2][x] = "."
    g[1][5] = "."
    # Right hall, mirrored, entered by a side shaft from the antechamber.
    for y in range(6, 15):
        g[y][11] = "."
    for x in range(7, 11):
        g[6][x] = "."
    g[7][7] = "."
    for y in (8, 9):
        g[y][7] = "."
    # Spikes face the long ceiling dashes. The stopper at the end of each dash stays a plain wall.
    for x in (2, 4):
        g[9][x] = "v"
    for x in (8, 9):
        g[5][x] = "v"
    for y in (8, 12, 13):
        g[y][10] = ">"
    # Turret in the outer wall, firing across the upper run.
    g[2][0] = "R"
    g[10][12] = "L"
    # A coin on the antechamber and a timed plate where the climb first stops.
    g[14][9] = "*"
    g[14][11] = "t"
    # Shared one-cell gate. Every chunk leaves and enters on column 6,
    # so a random stack still lines up. The side gate cells are walls.
    g[0] = list("######.######")
    g[1][5] = "#"
    g[1][6] = "."
    g[2][6] = "."
    g[h - 1] = list("######.######")
    # Остров в правом зале. С левой остановки вверх — шип потолка,
    # вниз — пролёт через нишу в шип. Нишу собирают с правой остановки.
    g[6][9] = "#"
    g[7][8] = "."
    g[7][9] = "."
    g[7][10] = "."
    g[8][8] = "^"
    # Тупик налево от той же ниши. Дэш останавливается у глухой стены,
    # шаг вверх или вниз — в шип. Назад по нише путь свободен.
    g[7][5] = "."
    g[7][4] = "."
    g[7][3] = "."
    return arm_spikes(["".join(r) for r in g])


# Символ шипа, который смотрит из стены обратно на игрока.
_SPIKE_CHAR = {
    (0, -1): "v",
    (0, 1): "^",
    (-1, 0): ">",
    (1, 0): "<",
}


def arm_spikes(rows: list[str]) -> list[str]:
    """Ставит шип на свободную грань каждой остановки.

    Грань, которой дэш и так заканчивается, не трогаем: иначе обязательный
    проход станет смертельным. Остальные глухие стороны — ловушка.
    """
    floors, spikes, entry, _exit = parse(rows)
    stops = set(entry)
    arrivals: dict[tuple[int, int], set[tuple[int, int]]] = {cell: set() for cell in entry}
    queue = list(entry)
    while queue:
        pos = queue.pop(0)
        for direction in DIRS:
            cells = slide(floors, spikes, pos, direction)
            if not cells:
                continue
            stop = cells[-1]
            arrivals.setdefault(stop, set()).add(direction)
            if stop not in stops:
                stops.add(stop)
                queue.append(stop)
    grid = [list(row) for row in rows]
    for pos in stops:
        for direction in DIRS:
            if direction in arrivals.get(pos, ()):
                continue
            nxt = (pos[0] + direction[0], pos[1] + direction[1])
            if nxt in floors or nxt in spikes:
                continue
            x, y = nxt
            if x <= 0 or y < 0 or x >= W - 1 or y >= len(grid):
                continue
            if grid[y][x] != "#":
                continue
            grid[y][x] = _SPIKE_CHAR[direction]
    return ["".join(row) for row in grid]


def mirror(rows: list[str]) -> list[str]:
    flip = {"<": ">", ">": "<", "L": "R", "R": "L"}
    return ["".join(flip.get(ch, ch) for ch in reversed(row)) for row in rows]


def build_pocket() -> list[str]:
    """Same spine as the first hall, plus a 3-wide pocket under the upper run."""
    g = [list(row) for row in build_r()]
    # Hang the pocket off the column-6 stop, so the new gate does not skip it.
    g[3][6] = "."
    g[3][5] = "."
    g[3][4] = "."
    g[4][4] = "."
    return arm_spikes(["".join(row) for row in g])


def build_side() -> list[str]:
    """Pocket chunk plus a side bay off the lower hall's right-hand stop."""
    g = [list(row) for row in build_pocket()]
    g[12][6] = "."
    g[12][7] = "."
    g[13][8] = "."
    g[12][8] = "."
    return arm_spikes(["".join(row) for row in g])


CHUNKS = {
"R": build_r(),
"M": mirror(build_r()),
"P": build_pocket(),
"S": build_side(),
"OLD": [
"#####...#####",
"#...........#",
"#.##........#",
"#.##........#",
"#####.......#",
"#.......#####",
"#........##.#",
"#........##.#",
"#.......#####",
"#####.......#",
"#.##........#",
"#.##........#",
"#...........#",
"#....###....#",
"#...........#",
"#####...#####",
"#####...#####",
],
"A": [
"#####...#####",
"#.......#...#",
"#..#....#...#",
"#.......#...#",
"#.......#####",
"#...#.......#",
"#...#..#....#",
"#...#.......#",
"#####.......#",
"#.......#...#",
"#..#....#...#",
"#.......#...#",
"#####...#####",
"#####...#####",
],
"B": [
"#####...#####",
"#####...#####",
"#...#####...#",
"#...#...#...#",
"#...#.#.#...#",
"#...#...#...#",
"#...#####...#",
"#####...#####",
"#...#####...#",
"#...#.#.#...#",
"#...#...#...#",
"#...#####...#",
"#####...#####",
"#####...#####",
],
"C": [
"#####...#####",
"#...........#",
"#..#.....#..#",
"#..#.....#..#",
"#...........#",
"###########.#",
"#...........#",
"#.#.........#",
"#...........#",
"#.###########",
"#...........#",
"#.........#.#",
"#...........#",
"#####...#####",
],
}

def stitch(a: list[str], b: list[str]) -> list[str]:
    """Stack b above a. b's entry sits directly above a's exit."""
    return list(b) + list(a)


def pair_missing(a: list[str], b: list[str]) -> int:
    rows = stitch(a, b)
    # Entry of the lower chunk is the start. Exit of the upper chunk must be seen.
    floors, spikes, entry, exit_ = parse(rows)
    if not entry or not exit_:
        return -1
    seen = set(entry)
    stops = set(entry)
    queue = list(entry)
    while queue:
        pos = queue.pop(0)
        for direction in DIRS:
            cells = slide(floors, spikes, pos, direction)
            if not cells:
                continue
            seen.update(cells)
            stop = cells[-1]
            if stop not in stops:
                stops.add(stop)
                queue.append(stop)
    return len([c for c in floors if c not in seen]) + len([c for c in exit_ if c not in seen])


def lethal_options(rows: list[str]) -> list[tuple[tuple[int, int], tuple[int, int]]]:
    floors, spikes, entry, _exit = parse(rows)
    seen = set(entry)
    stops = set(entry)
    queue = list(entry)
    while queue:
        pos = queue.pop(0)
        for direction in DIRS:
            cells = slide(floors, spikes, pos, direction)
            if not cells:
                continue
            seen.update(cells)
            stop = cells[-1]
            if stop not in stops:
                stops.add(stop)
                queue.append(stop)
    found = []
    for pos in stops:
        for direction in DIRS:
            step = (pos[0] + direction[0], pos[1] + direction[1])
            if step in floors:
                # Longer bait: walk floors until a spike or a wall.
                cursor = pos
                lethal = False
                for _ in range(12):
                    nxt = (cursor[0] + direction[0], cursor[1] + direction[1])
                    if kills(spikes, nxt, direction):
                        lethal = True
                        break
                    if nxt not in floors:
                        break
                    cursor = nxt
                if not lethal:
                    continue
            elif not kills(spikes, step, direction):
                continue
            found.append((pos, direction))
    return found


if __name__ == "__main__":
    live = {name: rows for name, rows in CHUNKS.items() if name in {"R", "M", "P", "S"}}
    live["MP"] = mirror(build_pocket())
    live["MS"] = mirror(build_side())
    for name, rows in live.items():
        missing = covers(rows)
        traps = lethal_options(rows)
        print(name, "missing", len(missing), "traps", len(traps), traps[:8])
        if name == "R" and missing:
            show(rows)
        if missing:
            show(rows)
    print("--- pairs ---")
    bad = 0
    for na, a in live.items():
        for nb, b in live.items():
            lost = pair_missing(a, b)
            if lost:
                bad += 1
                print(f"{na}->{nb} missing {lost}")
    print("bad pairs", bad)
