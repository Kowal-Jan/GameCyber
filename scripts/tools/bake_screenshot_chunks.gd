extends SceneTree
## Четыре уровня со скринов, ужатые до 13 клеток. Синий тайлсет собирается заново.

const TILE := 16
const WIDTH := 13
const TILESET_PATH := "res://assets/tiles/draft_tileset.tres"
const CHUNK_DIR := "res://scenes/chunks"
const FIELD := Color("16325c")
const TRACE := Color("3a629e")
const NODE := Color("4a78b8")
const MID := Color("4b5bab")
const NEON := Color("4da6ff")
const GROOVE := Color("0c1a36")
const SPIKE := {
	"^": Vector2i.UP,
	"v": Vector2i.DOWN,
	"<": Vector2i.LEFT,
	">": Vector2i.RIGHT,
}
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


func _init() -> void:
	push_error("Автогенерация отключена: игра собирает уровень только из готовых чанков.")
	quit(0)
	return
# 	var tileset := _build_tileset()
# 	if ResourceSaver.save(tileset, TILESET_PATH) != OK:
# 		push_error("Синий тайлсет не сохранён")
# 		quit()
# 		return
# 	tileset = load(TILESET_PATH) as TileSet
# 	print("Синий тайлсет восстановлен")
# 	var levels := {
# 		"chunk_08": _violet(),
# 		"chunk_09": _green(),
# 		"chunk_10": _red(),
# 		"chunk_11": _gray(),
# 	}
# 	for id in levels:
# 		var rows: Array = levels[id]
# 		if not _rows_ok(id, rows):
# 			quit()
# 			return
# 		var missing := _missing(rows)
# 		if not missing.is_empty():
# 			push_error("%s непроходим: %s" % [id, missing])
# 			quit()
# 			return
# 	var spike_scene := load("res://scenes/hazards/spike.tscn") as PackedScene
# 	var chunk_script := load("res://scripts/chunks/chunk.gd")
# 	for id in ["chunk_08", "chunk_09", "chunk_10", "chunk_11"]:
# 		var root := _build_chunk(levels[id], tileset, spike_scene, chunk_script)
# 		var packed := PackedScene.new()
# 		var pack_err := packed.pack(root)
# 		root.free()
# 		if pack_err != OK:
# 			push_error("Не упакован %s" % id)
# 			quit()
# 			return
# 		var path := "%s/%s.tscn" % [CHUNK_DIR, id]
# 		if ResourceSaver.save(packed, path) != OK:
# 			push_error("Не сохранён %s" % path)
# 			quit()
# 			return
# 		print("Сохранён ", path)
# 	_audit_library()
# 	quit()


# func _rows_ok(id: String, rows: Array) -> bool:
# 	if rows.size() < 8:
# 		push_error("%s слишком низкий" % id)
# 		return false
# 	for row in rows:
# 		if (row as String).length() != WIDTH:
# 			push_error("%s ширина не 13: %s" % [id, row])
# 			return false
# 	return true


# func _violet() -> Array:
# 	return [
# 		"#####>.<#####",
# 		"######.######",
# 		"#......######",
# 		"#.###########",
# 		"#...........#",
# 		"##v####.v####",
# 		"#.....#*....#",
# 		"#.###.#.###.#",
# 		"#.##>.#.##>.#",
# 		"#.###.#.###.#",
# 		"#.###...###.#",
# 		"#.#########.#",
# 		"#...........#",
# 		"###########.#",
# 		"#...........#",
# 		"#.###########",
# 		"#...........#",
# 		"#.#########.#",
# 		"#...........#",
# 		"#####>.<#####",
# 	]


# func _green() -> Array:
# 	return [
# 		"#####>.<#####",
# 		"######.######",
# 		"######......#",
# 		"###########.#",
# 		"#...........#",
# 		"#^###.<######",
# 		"#.....#.....#",
# 		"#.###.#.#^#.#",
# 		"#.##>.#.###.#",
# 		"#.###.#.###.#",
# 		"#.###.*.###.#",
# 		"#.#########.#",
# 		"#...........#",
# 		"#.###########",
# 		"#...........#",
# 		"###########.#",
# 		"#...........#",
# 		"#.#########.#",
# 		"#...........#",
# 		"#####>.<#####",
# 	]


# func _red() -> Array:
# 	return [
# 		"#####>.<#####",
# 		"######.######",
# 		"#......######",
# 		"#.###########",
# 		"#...........#",
# 		"##v####v###.#",
# 		"#...........#",
# 		"#.########v##",
# 		"#.....*.....#",
# 		"###v#######.#",
# 		"#...........#",
# 		"#.####v######",
# 		"#...........#",
# 		"###########.#",
# 		"#...........#",
# 		"#.###########",
# 		"#...........#",
# 		"#.#########.#",
# 		"#...........#",
# 		"#####>.<#####",
# 	]


# func _gray() -> Array:
# 	return [
# 		"#####>.<#####",
# 		"######.######",
# 		"#......######",
# 		"#.###########",
# 		"#........####",
# 		"##^####v.####",
# 		"##.......####",
# 		"##.#######v##",
# 		"##....*.....#",
# 		"###^#######.#",
# 		"###.........#",
# 		"###.#########",
# 		"###.......###",
# 		"#########.###",
# 		"#.........###",
# 		"#.###########",
# 		"#...........#",
# 		"#.#########.#",
# 		"#...........#",
# 		"#####>.<#####",
# 	]


# func _build_chunk(rows: Array, tileset: TileSet, spike_scene: PackedScene, chunk_script: Script) -> Node2D:
# 	var root := Node2D.new()
# 	root.name = "Chunk"
# 	root.set_script(chunk_script)
# 	var walls := TileMapLayer.new()
# 	walls.name = "WallsLayer"
# 	walls.tile_set = tileset
# 	walls.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
# 	root.add_child(walls)
# 	var dots := TileMapLayer.new()
# 	dots.name = "DotsLayer"
# 	dots.tile_set = tileset
# 	dots.z_index = 1
# 	dots.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
# 	root.add_child(dots)
# 	var hazards := Node2D.new()
# 	hazards.name = "Hazards"
# 	hazards.z_index = 2
# 	root.add_child(hazards)
# 	for y in rows.size():
# 		var row: String = rows[y]
# 		for x in WIDTH:
# 			var ch := row[x]
# 			if _is_wall(rows, x, y):
# 				var mask := _mask(rows, x, y)
# 				walls.set_cell(Vector2i(x, y), 0, Vector2i(mask % 4, int(mask / 4.0)))
# 			if ch == ".":
# 				dots.set_cell(Vector2i(x, y), 1, Vector2i(0, 0))
# 			elif ch == "*":
# 				dots.set_cell(Vector2i(x, y), 1, Vector2i(1, 0))
# 			if SPIKE.has(ch):
# 				var node := spike_scene.instantiate() as Node2D
# 				node.name = "Spike_%d_%d" % [x, y]
# 				node.position = Vector2(x * TILE + 8, y * TILE + 8)
# 				node.set("tile", Vector2i(x, y))
# 				node.set("direction", SPIKE[ch])
# 				hazards.add_child(node)
# 	var entry := Marker2D.new()
# 	entry.name = "EntryMarker"
# 	entry.position = Vector2(6 * TILE + 8, (rows.size() - 1) * TILE + 8)
# 	root.add_child(entry)
# 	var exit := Marker2D.new()
# 	exit.name = "ExitMarker"
# 	exit.position = Vector2(6 * TILE + 8, 8)
# 	root.add_child(exit)
# 	_own(root, root)
# 	return root


# func _own(root: Node, node: Node) -> void:
# 	if node != root:
# 		node.owner = root
# 	for child in node.get_children():
# 		_own(root, child)


# func _is_wall(rows: Array, x: int, y: int) -> bool:
# 	if x < 0 or y < 0 or x >= WIDTH or y >= rows.size():
# 		return false
# 	var ch: String = rows[y][x]
# 	return not (ch in ".*")


# func _mask(rows: Array, x: int, y: int) -> int:
# 	var mask := 0
# 	if _is_wall(rows, x, y - 1):
# 		mask |= 1
# 	if _is_wall(rows, x + 1, y):
# 		mask |= 2
# 	if _is_wall(rows, x, y + 1):
# 		mask |= 4
# 	if _is_wall(rows, x - 1, y):
# 		mask |= 8
# 	return mask


# func _ch_at(rows: Array, x: int, y: int) -> String:
# 	var h := rows.size()
# 	if y == -3 or y == h + 3:
# 		return "#"
# 	if y == -1 or y == -2 or y == h or y == h + 1 or y == h + 2:
# 		return "." if x == 6 else "#"
# 	if x < 0 or x >= WIDTH or y < 0 or y >= h:
# 		return "#"
# 	return rows[y][x]


# func _floor(rows: Array, x: int, y: int) -> bool:
# 	return _ch_at(rows, x, y) in ".*"


# func _kills(rows: Array, x: int, y: int, dir: Vector2i) -> bool:
# 	var ch := _ch_at(rows, x, y)
# 	if not SPIKE.has(ch):
# 		return false
# 	var danger: Vector2i = SPIKE[ch]
# 	return Vector2(dir).dot(Vector2(danger)) < -0.7


# func _slide(rows: Array, start: Vector2i, dir: Vector2i) -> Array[Vector2i]:
# 	var nxt := start + dir
# 	if _kills(rows, nxt.x, nxt.y, dir) or not _floor(rows, nxt.x, nxt.y):
# 		return []
# 	var cells: Array[Vector2i] = []
# 	var pos := start
# 	for _i in 100:
# 		nxt = pos + dir
# 		if _kills(rows, nxt.x, nxt.y, dir):
# 			return []
# 		if not _floor(rows, nxt.x, nxt.y):
# 			return cells
# 		cells.append(nxt)
# 		pos = nxt
# 	return []


# func _missing(rows: Array) -> Array:
# 	var start := Vector2i(6, rows.size() - 2)
# 	var seen := {start: true}
# 	var stops := {start: true}
# 	var queue: Array[Vector2i] = [start]
# 	while not queue.is_empty():
# 		var pos: Vector2i = queue.pop_front()
# 		for dir in DIRS:
# 			var cells := _slide(rows, pos, dir)
# 			if cells.is_empty():
# 				continue
# 			for cell in cells:
# 				seen[cell] = true
# 			var stop: Vector2i = cells[cells.size() - 1]
# 			if not stops.has(stop):
# 				stops[stop] = true
# 				queue.append(stop)
# 	var missing: Array = []
# 	for y in rows.size():
# 		var row: String = rows[y]
# 		for x in WIDTH:
# 			if row[x] in ".*" and not seen.has(Vector2i(x, y)):
# 				missing.append(Vector2i(x, y))
# 	return missing


# func _audit_library() -> void:
# 	var dir := DirAccess.open(CHUNK_DIR)
# 	var names: PackedStringArray = dir.get_files()
# 	names.sort()
# 	var stack: Array = []
# 	for file_name in names:
# 		if not file_name.ends_with(".tscn"):
# 			continue
# 		var packed := load(CHUNK_DIR + "/" + file_name) as PackedScene
# 		var node := packed.instantiate()
# 		var rows := _read_rows(node)
# 		node.free()
# 		var gate := _ch_at(rows, 6, 0) + _ch_at(rows, 6, 1) + _ch_at(rows, 6, 2) + _ch_at(rows, 6, 3)
# 		var bottom := rows.size() - 1
# 		var tail := _ch_at(rows, 6, bottom - 2) + _ch_at(rows, 6, bottom - 1) + _ch_at(rows, 6, bottom)
# 		print(file_name, " h=", rows.size(), " top6=", gate, " bot6=", tail)
# 		stack.append_array(rows)
# 	var missing := _missing(stack)
# 	if missing.is_empty():
# 		print("Стык всей колоды проходим")
# 	else:
# 		push_error("Стык колоды дырявый: %s" % missing.size())


# func _read_rows(node: Node) -> Array:
# 	var dots: TileMapLayer = node.get_node("DotsLayer")
# 	var hazards: Node = node.get_node("Hazards")
# 	var floors := {}
# 	var stars := {}
# 	var spikes := {}
# 	var max_y := 0
# 	for cell in dots.get_used_cells():
# 		floors[cell] = true
# 		if dots.get_cell_atlas_coords(cell) == Vector2i(1, 0):
# 			stars[cell] = true
# 		max_y = maxi(max_y, cell.y)
# 	for child in hazards.get_children():
# 		var path := ""
# 		if child.get_script() != null:
# 			path = child.get_script().resource_path
# 		if not path.ends_with("spike_hazard.gd"):
# 			continue
# 		var tile: Vector2i = child.get("tile")
# 		spikes[tile] = child.get("direction")
# 		max_y = maxi(max_y, tile.y)
# 	var rows: Array = []
# 	for y in max_y + 1:
# 		var line := ""
# 		for x in WIDTH:
# 			var here := Vector2i(x, y)
# 			if spikes.has(here):
# 				line += _glyph(spikes[here])
# 			elif stars.has(here):
# 				line += "*"
# 			elif floors.has(here):
# 				line += "."
# 			else:
# 				line += "#"
# 		rows.append(line)
# 	return rows


# func _glyph(direction: Vector2i) -> String:
# 	if direction == Vector2i.UP:
# 		return "^"
# 	if direction == Vector2i.DOWN:
# 		return "v"
# 	if direction == Vector2i.LEFT:
# 		return "<"
# 	return ">"


# func _build_tileset() -> TileSet:
# 	var tileset := TileSet.new()
# 	tileset.tile_size = Vector2i(TILE, TILE)
# 	tileset.add_terrain_set()
# 	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
# 	tileset.add_terrain(0, 0)
# 	tileset.set_terrain_color(0, 0, NEON)
# 	tileset.set_terrain_name(0, 0, "Wall")
# 	var walls := TileSetAtlasSource.new()
# 	walls.texture = ImageTexture.create_from_image(_wall_image())
# 	walls.texture_region_size = Vector2i(TILE, TILE)
# 	for mask in 16:
# 		var coords := Vector2i(mask % 4, int(mask / 4.0))
# 		walls.create_tile(coords)
# 		var data := walls.get_tile_data(coords, 0)
# 		data.terrain_set = 0
# 		data.terrain = 0
# 		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, 0 if (mask & 1) != 0 else -1)
# 		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, 0 if (mask & 2) != 0 else -1)
# 		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, 0 if (mask & 4) != 0 else -1)
# 		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, 0 if (mask & 8) != 0 else -1)
# 	tileset.add_source(walls, 0)
# 	var dots := TileSetAtlasSource.new()
# 	dots.texture = ImageTexture.create_from_image(_dot_image())
# 	dots.texture_region_size = Vector2i(TILE, TILE)
# 	dots.create_tile(Vector2i(0, 0))
# 	dots.create_tile(Vector2i(1, 0))
# 	tileset.add_source(dots, 1)
# 	return tileset


# func _wall_image() -> Image:
# 	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
# 	image.fill(Color(0, 0, 0, 0))
# 	for mask in 16:
# 		var origin := Vector2i((mask % 4) * TILE, int(mask / 4.0) * TILE)
# 		for y in TILE:
# 			for x in TILE:
# 				image.set_pixel(origin.x + x, origin.y + y, _wall_pixel(x, y, mask))
# 	return image


# func _wall_pixel(x: int, y: int, mask: int) -> Color:
# 	var dist := 99
# 	var along := 0
# 	if (mask & 1) == 0 and y < dist:
# 		dist = y
# 		along = x
# 	if (mask & 4) == 0 and TILE - 1 - y < dist:
# 		dist = TILE - 1 - y
# 		along = x
# 	if (mask & 8) == 0 and x < dist:
# 		dist = x
# 		along = y
# 	if (mask & 2) == 0 and TILE - 1 - x < dist:
# 		dist = TILE - 1 - x
# 		along = y
# 	if dist == 0:
# 		return MID
# 	if dist == 1 or dist == 2:
# 		return NEON if (along % 8) < 4 else MID
# 	if dist == 3:
# 		return GROOVE
# 	return _interior(x, y)


# func _interior(x: int, y: int) -> Color:
# 	var edge := x == 0 or x == TILE - 1 or y == 0 or y == TILE - 1
# 	var cross := x == 7 or x == 8 or y == 7 or y == 8
# 	var node := (x == 7 or x == 8) and (y == 7 or y == 8)
# 	var frame := x >= 4 and x <= 11 and y >= 4 and y <= 11 and (x == 4 or x == 11 or y == 4 or y == 11)
# 	var rivet := mini(x, TILE - 1 - x) >= 2 and mini(x, TILE - 1 - x) <= 3 and mini(y, TILE - 1 - y) >= 2 and mini(y, TILE - 1 - y) <= 3
# 	if node:
# 		return NODE
# 	if edge or cross or frame or rivet:
# 		return TRACE
# 	return FIELD


# func _dot_image() -> Image:
# 	var image := Image.create(32, TILE, false, Image.FORMAT_RGBA8)
# 	image.fill(Color(0, 0, 0, 0))
# 	image.fill_rect(Rect2i(6, 6, 4, 4), Color("ffe14a"))
# 	var star := Color("fff6b0")
# 	image.fill_rect(Rect2i(22, 6, 4, 4), star)
# 	image.fill_rect(Rect2i(19, 7, 3, 2), star)
# 	image.fill_rect(Rect2i(26, 7, 3, 2), star)
# 	image.fill_rect(Rect2i(23, 3, 2, 3), star)
# 	image.fill_rect(Rect2i(23, 10, 2, 3), star)
# 	return image
