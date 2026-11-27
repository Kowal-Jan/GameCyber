@tool
extends Node
## Печёт чанки из текстовых карт: set_cell, префабы ловушек, PackedScene.
## В инспекторе этой сцены нажми Bake All Chunks, затем правь .tscn руками.

const TILE := 16
const WIDTH := 13
const TILESET_PATH := "res://assets/tiles/arcade_tileset.tres"
const CHUNK_DIR := "res://scenes/chunks"

const SPIKE := {
	"^": Vector2i.UP,
	"v": Vector2i.DOWN,
	"<": Vector2i.LEFT,
	">": Vector2i.RIGHT,
}
const SHOOT := {
	"U": Vector2i.UP,
	"D": Vector2i.DOWN,
	"L": Vector2i.LEFT,
	"R": Vector2i.RIGHT,
}
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

const TEMPLATES: Array = [
	[
		"#####>.<#####",
		"######.######",
		"R......######",
		"#.###########",
		"#.###########",
		"#......#vv###",
		"###v##...#..#",
		"###.........#",
		"###^##..^#>.#",
		"##v#v...###.#",
		"#.....#####.L",
		"#.###.#####.#",
		"#.#...####>.#",
		"#.#.######>.#",
		"#........*.t#",
		"#####>.<#####",
	],
	[
		"#####>.<#####",
		"######.######",
		"######......L",
		"###########.#",
		"###########.#",
		"###vv#......#",
		"#..#...##v###",
		"#.........###",
		"#.<#^..##^###",
		"#.###...v#v##",
		"R.#####.....#",
		"#.#####.###.#",
		"#.<####...#.#",
		"#.<######.#.#",
		"#t.*........#",
		"#####>.<#####",
	],
	[
		"#####>.<#####",
		"######.######",
		"R......######",
		"#.##...######",
		"#.##.########",
		"#......#vv###",
		"###v##...#..#",
		"###.........#",
		"###^##..^#>.#",
		"##v#v...###.#",
		"#.....#####.L",
		"#.###.#####.#",
		"#.#...####>.#",
		"#.#.######>.#",
		"#........*.t#",
		"#####>.<#####",
	],
	[
		"#####>.<#####",
		"######.######",
		"R......######",
		"#.##...######",
		"#.##.########",
		"#......#vv###",
		"###v##...#..#",
		"###.........#",
		"###^##..^#>.#",
		"##v#v...###.#",
		"#.....#####.L",
		"#.###.#####.#",
		"#.#......#>.#",
		"#.#.####.#>.#",
		"#........*.t#",
		"#####>.<#####",
	],
	[
		"#####>.<#####",
		"######.######",
		"######......L",
		"######...##.#",
		"########.##.#",
		"###vv#......#",
		"#..#...##v###",
		"#.........###",
		"#.<#^..##^###",
		"#.###...v#v##",
		"R.#####.....#",
		"#.#####.###.#",
		"#.<####...#.#",
		"#.<######.#.#",
		"#t.*........#",
		"#####>.<#####",
	],
	[
		"#####>.<#####",
		"######.######",
		"######......L",
		"######...##.#",
		"########.##.#",
		"###vv#......#",
		"#..#...##v###",
		"#.........###",
		"#.<#^..##^###",
		"#.###...v#v##",
		"R.#####.....#",
		"#.#####.###.#",
		"#.<#......#.#",
		"#.<#.####.#.#",
		"#t.*........#",
		"#####>.<#####",
	],
]

var bake_ok := false

@export_tool_button("Bake All Chunks") var bake_chunks: Callable = bake_all


func bake_all() -> void:
	bake_ok = false
	push_error("chunk_01..06 больше не запекаются: аркада играет только сценами, которые лежат в scenes/chunks.")
	return
# 	for index in TEMPLATES.size():
# 		if not _solvable(TEMPLATES[index]):
# 			push_error("Чанк %02d непроходим" % [index + 1])
# 			return
# 		var nxt: Array = TEMPLATES[(index + 1) % TEMPLATES.size()]
# 		if not _solvable(_stitch(TEMPLATES[index], nxt)):
# 			push_error("Стык %02d -> следующего непроходим" % [index + 1])
# 			return
# 	var tileset := _build_tileset()
# 	if tileset == null:
# 		return
# 	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHUNK_DIR))
# 	var spike_scene := load("res://scenes/hazards/spike.tscn") as PackedScene
# 	var shooter_scene := load("res://scenes/hazards/shooter.tscn") as PackedScene
# 	var timed_scene := load("res://scenes/hazards/timed_spike.tscn") as PackedScene
# 	var chunk_script := load("res://scripts/chunks/chunk.gd")
# 	for index in TEMPLATES.size():
# 		var root := _build_chunk(TEMPLATES[index], tileset, spike_scene, shooter_scene, timed_scene, chunk_script)
# 		var packed := PackedScene.new()
# 		var pack_err := packed.pack(root)
# 		root.free()
# 		if pack_err != OK:
# 			push_error("Не удалось упаковать чанк %02d" % [index + 1])
# 			return
# 		var path := "%s/chunk_%02d.tscn" % [CHUNK_DIR, index + 1]
# 		if ResourceSaver.save(packed, path) != OK:
# 			push_error("Не удалось сохранить %s" % path)
# 			return
# 		print("Сохранён ", path)
# 	bake_ok = true
# 	print("Чанки запечены: ", TEMPLATES.size())


# func _build_chunk(rows: Array, tileset: TileSet, spike_scene: PackedScene, shooter_scene: PackedScene, timed_scene: PackedScene, chunk_script: Script) -> Node2D:
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
# 			if ch == "." or ch == "t":
# 				dots.set_cell(Vector2i(x, y), 1, Vector2i(0, 0))
# 			elif ch == "*":
# 				dots.set_cell(Vector2i(x, y), 1, Vector2i(1, 0))
# 			if SPIKE.has(ch):
# 				_place(hazards, spike_scene, x, y, SPIKE[ch])
# 			elif SHOOT.has(ch):
# 				_place(hazards, shooter_scene, x, y, SHOOT[ch])
# 			elif ch == "t":
# 				_place(hazards, timed_scene, x, y, Vector2i.ZERO)
# 	var entry := Marker2D.new()
# 	entry.name = "EntryMarker"
# 	entry.position = _center(6, rows.size() - 1)
# 	root.add_child(entry)
# 	var exit := Marker2D.new()
# 	exit.name = "ExitMarker"
# 	exit.position = _center(6, 0)
# 	root.add_child(exit)
# 	_own(root, root)
# 	return root


# func _place(parent: Node, scene: PackedScene, x: int, y: int, direction: Vector2i) -> void:
# 	var node := scene.instantiate() as Node2D
# 	node.name = "%s_%d_%d" % [node.name, x, y]
# 	node.position = _center(x, y)
# 	node.set("tile", Vector2i(x, y))
# 	if direction != Vector2i.ZERO:
# 		node.set("direction", direction)
# 	parent.add_child(node)


# func _center(x: int, y: int) -> Vector2:
# 	return Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)


# func _own(root: Node, node: Node) -> void:
# 	if node != root:
# 		node.owner = root
# 	for child in node.get_children():
# 		_own(root, child)


# func _is_wall(rows: Array, x: int, y: int) -> bool:
# 	if x < 0 or y < 0 or x >= WIDTH or y >= rows.size():
# 		return false
# 	var ch: String = rows[y][x]
# 	return not (ch in ".t*")


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


# func _build_tileset() -> TileSet:
# 	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/tiles"))
# 	var tileset := TileSet.new()
# 	tileset.tile_size = Vector2i(TILE, TILE)
# 	tileset.add_terrain_set()
# 	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
# 	tileset.add_terrain(0, 0)
# 	tileset.set_terrain_color(0, 0, Color("7dffe0"))
# 	tileset.set_terrain_name(0, 0, "Wall")
# 	var wall_tex := ImageTexture.create_from_image(_wall_image())
# 	var walls := TileSetAtlasSource.new()
# 	walls.texture = wall_tex
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
# 	var dot_tex := ImageTexture.create_from_image(_dot_image())
# 	var dots := TileSetAtlasSource.new()
# 	dots.texture = dot_tex
# 	dots.texture_region_size = Vector2i(TILE, TILE)
# 	dots.create_tile(Vector2i(0, 0))
# 	dots.create_tile(Vector2i(1, 0))
# 	tileset.add_source(dots, 1)
# 	if ResourceSaver.save(tileset, TILESET_PATH) != OK:
# 		push_error("Не удалось сохранить тайлсет")
# 		return null
# 	return load(TILESET_PATH) as TileSet


# func _wall_image() -> Image:
# 	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
# 	image.fill(Color(0, 0, 0, 0))
# 	var fill := Color("0e6b5c")
# 	var rim := Color("7dffe0")
# 	for mask in 16:
# 		var ox := (mask % 4) * TILE
# 		var oy := int(mask / 4.0) * TILE
# 		image.fill_rect(Rect2i(ox, oy, TILE, TILE), fill)
# 		if (mask & 1) == 0:
# 			image.fill_rect(Rect2i(ox, oy, TILE, 3), rim)
# 		if (mask & 2) == 0:
# 			image.fill_rect(Rect2i(ox + TILE - 3, oy, 3, TILE), rim)
# 		if (mask & 4) == 0:
# 			image.fill_rect(Rect2i(ox, oy + TILE - 3, TILE, 3), rim)
# 		if (mask & 8) == 0:
# 			image.fill_rect(Rect2i(ox, oy, 3, TILE), rim)
# 	return image


# func _dot_image() -> Image:
# 	var image := Image.create(32, TILE, false, Image.FORMAT_RGBA8)
# 	image.fill(Color(0, 0, 0, 0))
# 	image.fill_rect(Rect2i(6, 6, 4, 4), Color("ffe14a"))
# 	var star := Color("fff6b0")
# 	image.fill_rect(Rect2i(16 + 6, 6, 4, 4), star)
# 	image.fill_rect(Rect2i(16 + 3, 7, 3, 2), star)
# 	image.fill_rect(Rect2i(16 + 10, 7, 3, 2), star)
# 	image.fill_rect(Rect2i(16 + 7, 3, 2, 3), star)
# 	image.fill_rect(Rect2i(16 + 7, 10, 2, 3), star)
# 	return image


# func _stitch(lower: Array, upper: Array) -> Array:
# 	var rows: Array = []
# 	rows.append_array(upper)
# 	rows.append_array(lower)
# 	return rows


# func _solvable(rows: Array) -> bool:
# 	var floors := {}
# 	var spikes := {}
# 	for y in rows.size():
# 		var row: String = rows[y]
# 		if row.length() != WIDTH:
# 			push_error("Ширина строки %s = %s" % [y, row.length()])
# 			return false
# 		for x in WIDTH:
# 			var ch := row[x]
# 			if ch in ".t*":
# 				floors[Vector2i(x, y)] = true
# 			elif SPIKE.has(ch):
# 				spikes[Vector2i(x, y)] = SPIKE[ch]
# 			elif ch == "#" or SHOOT.has(ch):
# 				pass
# 			else:
# 				push_error("Неизвестный символ %s" % ch)
# 				return false
# 	var entry := Vector2i(6, rows.size() - 1)
# 	var exit := Vector2i(6, 0)
# 	if not floors.has(entry) or not floors.has(exit):
# 		return false
# 	var seen := {entry: true}
# 	var stops := {entry: true}
# 	var queue: Array[Vector2i] = [entry]
# 	while not queue.is_empty():
# 		var pos: Vector2i = queue.pop_front()
# 		for dir in DIRS:
# 			var cells := _slide(floors, spikes, pos, dir)
# 			if cells.is_empty():
# 				continue
# 			for cell in cells:
# 				seen[cell] = true
# 			var stop: Vector2i = cells[cells.size() - 1]
# 			if not stops.has(stop):
# 				stops[stop] = true
# 				queue.append(stop)
# 	for key in floors.keys():
# 		if not seen.has(key):
# 			return false
# 	return seen.has(exit)


# func _slide(floors: Dictionary, spikes: Dictionary, start: Vector2i, dir: Vector2i) -> Array[Vector2i]:
# 	var nxt := start + dir
# 	if _kills(spikes, nxt, dir) or not floors.has(nxt):
# 		return []
# 	var cells: Array[Vector2i] = []
# 	var pos := start
# 	for _step in 80:
# 		nxt = pos + dir
# 		if _kills(spikes, nxt, dir):
# 			return []
# 		if not floors.has(nxt):
# 			return cells
# 		pos = nxt
# 		cells.append(pos)
# 	return []


# func _kills(spikes: Dictionary, cell: Vector2i, move: Vector2i) -> bool:
# 	if not spikes.has(cell):
# 		return false
# 	var danger: Vector2i = spikes[cell]
# 	return Vector2(move).dot(Vector2(danger)) < -0.7
