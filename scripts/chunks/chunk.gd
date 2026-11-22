extends Node2D
## Один запечённый кусок уровня. Клетки локальные, мир считает ChunkManager.

var game
var origin := Vector2i.ZERO
var dot_cells: Dictionary = {}
var spike_cells: Array[Vector2i] = []
var shooter_cells: Array[Vector2i] = []
var timed_cells: Array[Vector2i] = []
var entry_cell := Vector2i.ZERO
var exit_cell := Vector2i.ZERO


func activate(host_game, world_origin: Vector2i) -> void:
	game = host_game
	origin = world_origin
	dot_cells.clear()
	spike_cells.clear()
	shooter_cells.clear()
	timed_cells.clear()
	var dots: TileMapLayer = $DotsLayer
	for cell in dots.get_used_cells():
		var world: Vector2i = origin + cell
		var atlas := dots.get_cell_atlas_coords(cell)
		game.carved[world] = 2 if atlas == Vector2i(1, 0) else 1
		dot_cells[world] = cell
	for child in $Hazards.get_children():
		if child.has_method("register"):
			child.register(self, origin)
	entry_cell = origin + _marker_cell($EntryMarker)
	exit_cell = origin + _marker_cell($ExitMarker)


func take_dot(world_cell: Vector2i) -> void:
	if not dot_cells.has(world_cell):
		return
	var local: Vector2i = dot_cells[world_cell]
	($DotsLayer as TileMapLayer).set_cell(local, -1)
	dot_cells.erase(world_cell)


func release() -> void:
	if game == null:
		return
	for world in dot_cells.keys():
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
