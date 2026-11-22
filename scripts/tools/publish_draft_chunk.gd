extends SceneTree
## Кладёт ручной черновик в аркаду и ставит точки на клетки, куда дэш реально доезжает.

const TILE := 16
const COLS := 13
const ROWS := 16
const OUT := "res://scenes/chunks/chunk_07.tscn"
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


func _init() -> void:
	var chunk := (load("res://scenes/editor/chunk_draft.tscn") as PackedScene).instantiate()
	var walls: TileMapLayer = chunk.get_node("WallsLayer")
	var dots: TileMapLayer = chunk.get_node("DotsLayer")
	var floors := {}
	var spikes := {}
	for y in ROWS:
		for x in COLS:
			var cell := Vector2i(x, y)
			if walls.get_cell_source_id(cell) == -1:
				floors[cell] = true
	for hazard in chunk.get_node("Hazards").get_children():
		if hazard.get("tile") != null and hazard.get("direction") != null and hazard.direction != Vector2i.ZERO:
			spikes[hazard.tile] = hazard.direction
			floors.erase(hazard.tile)
	var entry := _marker_cell(chunk.get_node("EntryMarker"))
	var exit_cell := _marker_cell(chunk.get_node("ExitMarker"))
	var seen := {entry: true}
	var stops := {entry: true}
	var queue: Array[Vector2i] = [entry]
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		for dir in DIRS:
			var cells := _slide(floors, spikes, pos, dir)
			if cells.is_empty():
				continue
			for cell in cells:
				seen[cell] = true
			var stop: Vector2i = cells[cells.size() - 1]
			if not stops.has(stop):
				stops[stop] = true
				queue.append(stop)
	var stars := {}
	for cell in dots.get_used_cells():
		if dots.get_cell_atlas_coords(cell) == Vector2i(1, 0):
			stars[cell] = true
	dots.clear()
	var drop: Array[Vector2i] = []
	for key in floors.keys():
		if not seen.has(key):
			drop.append(key)
	for cell in drop:
		floors.erase(cell)
	var added := 0
	for key in floors.keys():
		var cell: Vector2i = key
		var atlas := Vector2i(1, 0) if stars.has(cell) else Vector2i(0, 0)
		dots.set_cell(cell, 1, atlas)
		added += 1
	var missing := 0
	for key in floors.keys():
		if not seen.has(key):
			missing += 1
	print("Клеток маршрута: %s, дыр: %s, выход: %s" % [added, missing, seen.has(exit_cell)])
	if missing != 0 or not seen.has(exit_cell):
		push_error("Черновик не публикую: маршрут не сходится")
		quit(1)
		return
	var packed := PackedScene.new()
	packed.pack(chunk)
	var err := ResourceSaver.save(packed, OUT)
	if err != OK:
		push_error("Не сохранил чанк: %s" % err)
		quit(1)
		return
	print("Аркада: ", OUT)
	quit()


func _marker_cell(marker: Marker2D) -> Vector2i:
	return Vector2i(floori((marker.position.x - 8.0) / 16.0), floori((marker.position.y - 8.0) / 16.0))


func _slide(floors: Dictionary, spikes: Dictionary, start: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var nxt := start + dir
	if _kills(spikes, nxt, dir) or not floors.has(nxt):
		return []
	var cells: Array[Vector2i] = []
	var pos := start
	while cells.size() < 80:
		nxt = pos + dir
		if _kills(spikes, nxt, dir):
			return []
		if not floors.has(nxt):
			return cells
		pos = nxt
		cells.append(pos)
	return []


func _kills(spikes: Dictionary, cell: Vector2i, move: Vector2i) -> bool:
	if not spikes.has(cell):
		return false
	var danger: Vector2i = spikes[cell]
	return Vector2(move).dot(Vector2(danger)) < -0.7
