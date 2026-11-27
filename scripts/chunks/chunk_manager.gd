extends Node2D
## Подгружает запечённые чанки вверх и снимает те, что остались под лавой.

const TILE := 16
const CHUNK_DIR := "res://scenes/chunks"
var game
var library: Array[PackedScene] = []
var bag: Array[int] = []
var live: Array = []
var next_entry := Vector2i.ZERO
var started := false


func setup(host_game) -> void:
	game = host_game
	_load_library()
	if library.is_empty():
		push_error("Нет чанков в res://scenes/chunks.")
		return
	_refill_bag()
	# Вход первого чанка. Под ним нет пола, поэтому игрок сразу упирается в стену.
	next_entry = Vector2i(6, 2)
	_spawn()
	var start: Vector2i = live[0].entry_cell
	ensure_above(start.y - 70)
	game.player = start
	game.highest = game.player.y
	game.lava_y = game.player.y + 8
	game.head = live[live.size() - 1].exit_cell
	game.carved[game.player] = 0
	game.trail[game.player] = true
	live[0].take_dot(game.player)
	started = true


func ensure_above(target_y: int) -> void:
	if library.is_empty():
		return
	var guard := 0
	while guard < 12:
		guard += 1
		var top = live[live.size() - 1]
		if int(top.exit_cell.y) <= target_y:
			game.head = top.exit_cell
			return
		next_entry = top.exit_cell + Vector2i.UP
		_spawn()
	game.head = live[live.size() - 1].exit_cell


func free_below(lava_y: int) -> void:
	var limit := lava_y + 8
	var kept: Array = []
	for chunk in live:
		if int(chunk.exit_cell.y) > limit:
			chunk.release()
			chunk.queue_free()
		else:
			kept.append(chunk)
	live = kept


func take_dot(world_cell: Vector2i) -> void:
	for chunk in live:
		if chunk.dot_cells.has(world_cell):
			chunk.take_dot(world_cell)
			return


func _load_library() -> void:
	library.clear()
	var dir := DirAccess.open(CHUNK_DIR)
	if dir == null:
		return
	var names: PackedStringArray = dir.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tscn"):
			continue
		# Старые запечённые шаблоны. Если вкладка ещё открыта, Godot записывает файл обратно при запуске.
		if file_name.substr(0, 8) in ["chunk_01", "chunk_02", "chunk_03", "chunk_04", "chunk_05", "chunk_06"]:
			continue
		var packed := load(CHUNK_DIR + "/" + file_name) as PackedScene
		if packed != null:
			library.append(packed)


func _refill_bag() -> void:
	bag.clear()
	for index in library.size():
		bag.append(index)
	bag.shuffle()


func _spawn() -> void:
	if bag.is_empty():
		_refill_bag()
	var index: int = bag.pop_back()
	var chunk = library[index].instantiate()
	var entry_marker := chunk.get_node("EntryMarker") as Marker2D
	var world_center := Vector2(next_entry.x * TILE + TILE * 0.5, next_entry.y * TILE + TILE * 0.5)
	chunk.position = world_center - entry_marker.position
	add_child(chunk)
	var entry_local := Vector2i(
		floori((entry_marker.position.x - 8.0) / float(TILE)),
		floori((entry_marker.position.y - 8.0) / float(TILE))
	)
	chunk.activate(game, next_entry - entry_local)
	live.append(chunk)
