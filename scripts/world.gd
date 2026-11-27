extends Node2D

const TILE := 16
const COLS := 13

# Старая отрисовка пола, стен и точек поверх тайлов чанков. Сейчас рисуют сами TileMapLayer.
# const FLOOR := Color("0a0a0f")
# const WALL_FILL := Color("0e6b5c")
# const RIM := Color("7dffe0")
# const DOT := Color("ffe14a")
# const STAR := Color("fff6b0")
const SPIKE := Color("b8fff4")
const TRAIL := Color("ffe14a")
const WARN := Color("ffb03a")
const SHOT := Color("ff3d9a")

var game: Node2D

var lava_tex: Texture2D
var lava_tex_b: Texture2D
var lava_top_tex: Texture2D
var lava_top_tex_b: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lava_tex = preload("res://assets/sprites/lava.png")
	lava_tex_b = preload("res://assets/sprites/lava_b.png")
	lava_top_tex = preload("res://assets/sprites/lava_top.png")
	lava_top_tex_b = preload("res://assets/sprites/lava_top_b.png")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var center := cam.global_position
	var view_size := get_viewport_rect().size
	var y0 := floori((center.y - view_size.y * 0.5) / float(TILE)) - 2
	var y1 := floori((center.y + view_size.y * 0.5) / float(TILE)) + 2
	for y in range(y0, y1 + 1):
		for x in range(COLS):
			var cell := Vector2i(x, y)
			var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			if y >= int(game.lava_y):
				_draw_lava(rect, y)
			elif game.trail.has(cell):
				draw_rect(rect, TRAIL)
			elif game.trap_until > 0 and game.trap_cell == cell:
				_draw_warn(rect)
	for bullet in game.bullets:
		var pos: Vector2 = bullet["pos"]
		var dir: Vector2i = bullet["dir"]
		var size := Vector2(8, 3) if dir.x != 0 else Vector2(3, 8)
		draw_rect(Rect2(pos - size * 0.5, size), SHOT)


func _draw_warn(rect: Rect2) -> void:
	var warn := WARN
	if int(Time.get_ticks_msec() / 90) % 2 == 0:
		warn = SPIKE
	draw_rect(Rect2(rect.position, Vector2(TILE, 2)), warn)
	draw_rect(Rect2(rect.position + Vector2(0, TILE - 2), Vector2(TILE, 2)), warn)
	draw_rect(Rect2(rect.position, Vector2(2, TILE)), warn)
	draw_rect(Rect2(rect.position + Vector2(TILE - 2, 0), Vector2(2, TILE)), warn)


func _draw_lava(rect: Rect2, y: int) -> void:
	var crest := y == int(game.lava_y)
	var frame: int = game.lava_frame
	var tex := lava_top_tex if crest else lava_tex
	if frame == 1:
		tex = lava_top_tex_b if crest else lava_tex_b
	draw_texture_rect(tex, rect, false)


# func _draw_path(cell: Vector2i, rect: Rect2) -> void:
# 	draw_rect(rect, FLOOR)
# 	if game.trail.has(cell):
# 		draw_rect(rect, TRAIL)
# 	if game.timed_cells.has(cell):
# 		var armed: bool = game.trap_until > 0 and game.trap_cell == cell
# 		var warn := WARN
# 		if armed and int(Time.get_ticks_msec() / 90) % 2 == 0:
# 			warn = SPIKE
# 		draw_rect(Rect2(rect.position, Vector2(TILE, 2)), warn)
# 		draw_rect(Rect2(rect.position + Vector2(0, TILE - 2), Vector2(TILE, 2)), warn)
# 		draw_rect(Rect2(rect.position, Vector2(2, TILE)), warn)
# 		draw_rect(Rect2(rect.position + Vector2(TILE - 2, 0), Vector2(2, TILE)), warn)
# 	var kind := int(game.carved[cell])
# 	if kind == 1:
# 		draw_rect(Rect2(rect.position + Vector2(6, 6), Vector2(4, 4)), DOT)
# 	elif kind == 2:
# 		_draw_star(rect)


# func _mark_wall_faces(cell: Vector2i, rect: Rect2, spike_marks: Array[Vector3i]) -> void:
# 	var danger := Vector2i.ZERO
# 	if game.spike_walls.has(cell):
# 		danger = game.spike_walls[cell]
# 	for dir_index in 4:
# 		var dir := _dir_from_index(dir_index)
# 		var faces_floor: bool = game.carved.has(cell + dir)
# 		var screen_edge := (dir == Vector2i.LEFT and cell.x == 0) or (dir == Vector2i.RIGHT and cell.x == COLS - 1)
# 		if not faces_floor and not screen_edge:
# 			continue
# 		draw_rect(_rim_rect(rect, dir), RIM)
# 		if faces_floor and danger == dir:
# 			spike_marks.append(Vector3i(cell.x, cell.y, _pack_dir(dir)))


# func _draw_star(rect: Rect2) -> void:
# 	var c := rect.position + Vector2(6, 6)
# 	draw_rect(Rect2(c, Vector2(4, 4)), STAR)
# 	draw_rect(Rect2(c + Vector2(-3, 1), Vector2(3, 2)), STAR)
# 	draw_rect(Rect2(c + Vector2(4, 1), Vector2(3, 2)), STAR)
# 	draw_rect(Rect2(c + Vector2(1, -3), Vector2(2, 3)), STAR)
# 	draw_rect(Rect2(c + Vector2(1, 4), Vector2(2, 3)), STAR)


# func _pack_dir(dir: Vector2i) -> int:
# 	if dir.x != 0:
# 		return dir.x
# 	return dir.y * 2


# func _unpack_dir(packed: int) -> Vector2i:
# 	if absi(packed) == 1:
# 		return Vector2i(packed, 0)
# 	return Vector2i(0, int(packed / 2.0))


# func _draw_teeth_into(wall_cell: Vector2i, dir: Vector2i) -> void:
# 	var origin := Vector2((wall_cell + dir) * TILE)
# 	var depth := 7
# 	for i in 3:
# 		var along := 2 + i * 5
# 		var tooth := Rect2()
# 		if dir == Vector2i.DOWN:
# 			tooth = Rect2(origin + Vector2(along, 0), Vector2(3, depth))
# 		elif dir == Vector2i.UP:
# 			tooth = Rect2(origin + Vector2(along, TILE - depth), Vector2(3, depth))
# 		elif dir == Vector2i.RIGHT:
# 			tooth = Rect2(origin + Vector2(0, along), Vector2(depth, 3))
# 		else:
# 			tooth = Rect2(origin + Vector2(TILE - depth, along), Vector2(depth, 3))
# 		draw_rect(tooth, SPIKE)


# func _rim_rect(rect: Rect2, dir: Vector2i) -> Rect2:
# 	if dir == Vector2i.UP:
# 		return Rect2(rect.position, Vector2(TILE, 3))
# 	if dir == Vector2i.DOWN:
# 		return Rect2(rect.position + Vector2(0, TILE - 3), Vector2(TILE, 3))
# 	if dir == Vector2i.LEFT:
# 		return Rect2(rect.position, Vector2(3, TILE))
# 	return Rect2(rect.position + Vector2(TILE - 3, 0), Vector2(3, TILE))


# func _shooter_at(cell: Vector2i) -> Vector2i:
# 	for shooter in game.shooters:
# 		if shooter["cell"] == cell:
# 			return shooter["dir"]
# 	return Vector2i.ZERO


# func _draw_shooter(rect: Rect2, dir: Vector2i) -> void:
# 	draw_rect(rect.grow(-3), SHOT)
# 	var barrel := Rect2(rect.position + Vector2(6, 6), Vector2(4, 4))
# 	if dir == Vector2i.UP:
# 		barrel = Rect2(rect.position + Vector2(6, 0), Vector2(4, 5))
# 	elif dir == Vector2i.DOWN:
# 		barrel = Rect2(rect.position + Vector2(6, TILE - 5), Vector2(4, 5))
# 	elif dir == Vector2i.LEFT:
# 		barrel = Rect2(rect.position + Vector2(0, 6), Vector2(5, 4))
# 	else:
# 		barrel = Rect2(rect.position + Vector2(TILE - 5, 6), Vector2(5, 4))
# 	draw_rect(barrel, SPIKE)


# func _dir_from_index(index: int) -> Vector2i:
# 	match index:
# 		0:
# 			return Vector2i.UP
# 		1:
# 			return Vector2i.RIGHT
# 		2:
# 			return Vector2i.DOWN
# 		_:
# 			return Vector2i.LEFT
