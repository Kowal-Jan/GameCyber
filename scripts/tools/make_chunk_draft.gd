extends SceneTree
## Пустой холст для ручной сборки. Не лежит в scenes/chunks, поэтому аркада его не грузит.


func _init() -> void:
	var tileset := load("res://assets/tiles/arcade_tileset.tres")
	var root := Node2D.new()
	root.name = "Chunk"
	root.set_script(load("res://scripts/chunks/chunk.gd"))
	var walls := TileMapLayer.new()
	walls.name = "WallsLayer"
	walls.tile_set = tileset
	walls.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(walls)
	var dots := TileMapLayer.new()
	dots.name = "DotsLayer"
	dots.tile_set = tileset
	dots.z_index = 1
	dots.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(dots)
	var hazards := Node2D.new()
	hazards.name = "Hazards"
	hazards.z_index = 2
	root.add_child(hazards)
	var height := 16
	var width := 13
	for y in height:
		for x in width:
			var border := x == 0 or x == width - 1 or y == 0 or y == height - 1
			var gate := x == 6 and (y == 0 or y == height - 1)
			if border and not gate:
				var mask := _mask(x, y, width, height)
				walls.set_cell(Vector2i(x, y), 0, Vector2i(mask % 4, int(mask / 4.0)))
	var entry := Marker2D.new()
	entry.name = "EntryMarker"
	entry.position = Vector2(6 * 16 + 8, (height - 1) * 16 + 8)
	root.add_child(entry)
	var exit := Marker2D.new()
	exit.name = "ExitMarker"
	exit.position = Vector2(6 * 16 + 8, 8)
	root.add_child(exit)
	_own(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err != OK:
		push_error("Не удалось упаковать черновик")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/editor"))
	var path := "res://scenes/editor/chunk_draft.tscn"
	if ResourceSaver.save(packed, path) != OK:
		push_error("Не удалось сохранить черновик")
		quit(1)
		return
	print("Черновик: ", path)
	quit(0)


func _mask(x: int, y: int, width: int, height: int) -> int:
	var mask := 0
	if _wall(x, y - 1, width, height):
		mask |= 1
	if _wall(x + 1, y, width, height):
		mask |= 2
	if _wall(x, y + 1, width, height):
		mask |= 4
	if _wall(x - 1, y, width, height):
		mask |= 8
	return mask


func _wall(x: int, y: int, width: int, height: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	var gate := x == 6 and (y == 0 or y == height - 1)
	return (x == 0 or x == width - 1 or y == 0 or y == height - 1) and not gate


func _own(root: Node, node: Node) -> void:
	if node != root:
		node.owner = root
	for child in node.get_children():
		_own(root, child)
