extends Node2D
## Один запечённый кусок уровня. Клетки локальные, мир считает ChunkManager.

const COLS := 13

var game
var origin := Vector2i.ZERO
var dot_cells: Dictionary = {}
var floor_cells: Dictionary = {}
var spike_cells: Array[Vector2i] = []
var shooter_cells: Array[Vector2i] = []
var timed_cells: Array[Vector2i] = []
var entry_cell := Vector2i.ZERO
var exit_cell := Vector2i.ZERO


func activate(host_game, world_origin: Vector2i) -> void:
	game = host_game
	origin = world_origin
	dot_cells.clear()
	floor_cells.clear()
	spike_cells.clear()
	shooter_cells.clear()
	timed_cells.clear()
	var walls: TileMapLayer = $WallsLayer
	var dots: TileMapLayer = $DotsLayer
	var entry_local := _marker_cell($EntryMarker)
	var exit_local := _marker_cell($ExitMarker)
	var y0 := mini(entry_local.y, exit_local.y)
	var y1 := maxi(entry_local.y, exit_local.y)
	for y in range(y0, y1 + 1):
		for x in COLS:
			var cell := Vector2i(x, y)
			if walls.get_cell_source_id(cell) != -1:
				continue
			var world := origin + cell
			game.carved[world] = 0
			floor_cells[world] = true
	for cell in dots.get_used_cells():
		if walls.get_cell_source_id(cell) != -1:
			continue
		var world: Vector2i = origin + cell
		var atlas := dots.get_cell_atlas_coords(cell)
		game.carved[world] = 2 if atlas == Vector2i(1, 0) else 1
		dot_cells[world] = cell
		floor_cells[world] = true
	for child in $Hazards.get_children():
		if child.has_method("register"):
			child.register(self, origin)
	entry_cell = origin + entry_local
	exit_cell = origin + exit_local


func take_dot(world_cell: Vector2i) -> void:
	if not dot_cells.has(world_cell):
		return
	var local: Vector2i = dot_cells[world_cell]
	($DotsLayer as TileMapLayer).set_cell(local, -1)
	dot_cells.erase(world_cell)


func release() -> void:
	if game == null:
		return
	for world in floor_cells.keys():
		game.carved.erase(world)
		game.trail.erase(world)
	for world in spike_cells:
		game.spike_walls.erase(world)
	for world in timed_cells:
		game.timed_cells.erase(world)
		if game.trap_cell == world:
			game.trap_until = 0
	if not shooter_cells.is_empty():
		var kept: Array[Dictionary] = []
		for shooter in game.shooters:
			var cell: Vector2i = shooter["cell"]
			if not shooter_cells.has(cell):
				kept.append(shooter)
		game.shooters = kept
	game = null


func _marker_cell(marker: Marker2D) -> Vector2i:
	return Vector2i(floori((marker.position.x - 8.0) / 16.0), floori((marker.position.y - 8.0) / 16.0))
