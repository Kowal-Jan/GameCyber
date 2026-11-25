extends Node2D
## Аркада: дэш по одной оси до стены. Поворот только после остановки.
## Шип убивает, если летишь в остриё. Вдоль грани — обычная стена.

const TILE := 16
const COLS := 13
const STEP_TIME := 0.028
const SWIPE_THRESHOLD := 14.0
const SAVE_PATH := "user://best.cfg"
const MAX_LAVA_LAG := 9
const CAMERA_LEAD := 96.0
const LOOKAHEAD := 70
const BULLET_SPEED := 180.0
const TRAP_DELAY_MS := 560
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

const CYAN := Color("3df0ff")
const MAGENTA := Color("ff3d9a")
const GOLD := Color("ffd84a")
const INK := Color("07060f")

var carved: Dictionary = {}
var spike_walls: Dictionary = {}
var timed_cells: Dictionary = {}
var trail: Dictionary = {}
var shooters: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var player := Vector2i(8, 0)
var head := Vector2i(8, 0)
var lava_y := 7
var lava_frame := 0
var lava_anim := 0.0
var lava_clock := 0.0
var grace := 1.4
var climbed := 0
var highest := 0
var score := 0
var best := 0
var alive := true
var sliding := false
var bumping := false
var slide_dir := Vector2i.ZERO
var queued_dir := Vector2i.ZERO
var slide_tween: Tween
var bump_tween: Tween
var swipe_origin := Vector2.ZERO
var swipe_tracking := false
var swipe_used := false
var restart_at := 0
var restarting := false
var run_seed := 0
var trap_cell := Vector2i(-999, -999)
var trap_until := 0
var anchor_x := 2
var anchor_on_left := true
var next_bottom := 0
var box_index := 0

@onready var world: Node2D = $World
var chunks
@onready var player_sprite: Sprite2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var ui: CanvasLayer = $UI

var score_label: Label
var best_label: Label
var hint_label: Label
var death_root: Control
var death_score: Label
var coin_sfx: AudioStreamPlayer
var bump_sfx: AudioStreamPlayer
var die_sfx: AudioStreamPlayer


func _ready() -> void:
	chunks = $Chunks
	run_seed = Time.get_ticks_msec()
	seed(run_seed)
	best = _load_best()
	_build_level()
	highest = player.y
	world.game = self
	player_sprite.texture = preload("res://assets/sprites/player.png")
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_sprite.centered = true
	player_sprite.z_index = 10
	player_sprite.scale = Vector2.ONE
	player_sprite.position = _grid_to_world(player)
	camera.position = _camera_target()
	_build_ui()
	_build_audio()
	_update_hud()
	if not _covers_paths():
		push_error("Маршрут непроходим, seed %s" % run_seed)
		_dump_level()
	print("GameTomb ready")


func _process(delta: float) -> void:
	_animate_lava(delta)
	if alive:
		_rise_lava(delta)
		_pull_lava()
		_update_hazards(delta)
		_check_trap()
		if not sliding and not bumping:
			var bob := 1.0 if int(Time.get_ticks_msec() / 280) % 2 == 0 else 0.0
			player_sprite.position = _grid_to_world(player) + Vector2(0, -bob)
	_update_camera(delta)
	_update_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_exit_to_menu()
		return
	if not alive:
		if Time.get_ticks_msec() >= restart_at and _is_confirm(event):
			_restart()
		return
	if not alive:
		if Time.get_ticks_msec() >= restart_at and _is_confirm(event):
			_restart()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_dir := _dir_from_key(event.keycode)
		if key_dir != Vector2i.ZERO:
			_begin_slide(key_dir)
	elif event is InputEventScreenTouch:
		if event.index != 0:
			return
		if event.pressed:
			swipe_origin = event.position
			swipe_tracking = true
			swipe_used = false
		else:
			swipe_tracking = false
	elif event is InputEventScreenDrag and swipe_tracking and not swipe_used and event.index == 0:
		var drag := event as InputEventScreenDrag
		var drag_delta := drag.position - swipe_origin
		if drag_delta.length() >= SWIPE_THRESHOLD:
			swipe_used = true
			_begin_slide(_dir_from_vector(drag_delta))


func _build_level() -> void:
	chunks.setup(self)


func _extend_to(target_y: int) -> void:
	chunks.ensure_above(target_y)


func _add_box() -> void:
	var y := next_bottom
	var left := 1
	var right := COLS - 2
	var entry_x := left if anchor_on_left else right
	var exit_x := right if anchor_on_left else left
	for x in range(left, right + 1):
		var cell := Vector2i(x, y)
		_carve(cell)
		_maybe_dot(cell)
	if box_index % 4 == 3:
		var star := Vector2i(left + (right - left) / 2, y)
		if star != player and carved.has(star):
			carved[star] = 2
	for step in range(1, 4):
		var shaft := Vector2i(exit_x, y - step)
		_carve(shaft)
		_maybe_dot(shaft)
	var pocket_width := 0
	if box_index % 2 == 0:
		pocket_width = 2 + (box_index % 3)
		_add_pocket(exit_x, y, pocket_width)
	for x in range(left + 4, right - 3):
		_add_spike(Vector2i(x, y - 1), Vector2i.DOWN)
		_add_spike(Vector2i(x, y + 1), Vector2i.UP)
	if box_index > 1 and box_index % 5 == 0:
		var from_left := entry_x == left
		shooters.append({
			"cell": Vector2i(0 if from_left else COLS - 1, y),
			"dir": Vector2i.RIGHT if from_left else Vector2i.LEFT,
			"wait": randf_range(0.9, 1.6),
			"interval": randf_range(1.7, 2.3),
		})
	elif pocket_width == 0 and box_index % 3 == 2:
		var gate := Vector2i(exit_x, y)
		if gate != player:
			timed_cells[gate] = true
	head = Vector2i(exit_x, y)
	next_bottom = y - 4
	anchor_x = exit_x
	anchor_on_left = exit_x == left
	box_index += 1


func _add_pocket(anchor: int, y: int, width: int) -> void:
	var inward := -1 if anchor > COLS / 2 else 1
	var coords: Array[Vector2i] = []
	coords.append(Vector2i(anchor, y + 1))
	coords.append(Vector2i(anchor + inward, y + 1))
	coords.append(Vector2i(anchor + inward, y + 2))
	if width >= 3:
		coords.append(Vector2i(anchor + inward * 2, y + 2))
	if width >= 4:
		coords.append(Vector2i(anchor + inward * 3, y + 2))
	for cell in coords:
		if not _in_playable(cell):
			return
	for cell in coords:
		_carve(cell)
		_maybe_dot(cell)


func _maybe_dot(cell: Vector2i) -> void:
	if cell == player or not carved.has(cell):
		return
	if int(carved[cell]) != 0:
		return
	carved[cell] = 1


func _add_spike(cell: Vector2i, danger: Vector2i) -> void:
	if cell == player + Vector2i.UP or cell == player + Vector2i.DOWN:
		return
	if not _in_playable(cell) or carved.has(cell) or spike_walls.has(cell):
		return
	spike_walls[cell] = danger


func _carve(cell: Vector2i) -> void:
	if not _in_playable(cell) or spike_walls.has(cell):
		return
	if not carved.has(cell):
		carved[cell] = 0


func _in_playable(cell: Vector2i) -> bool:
	return cell.x >= 1 and cell.x <= COLS - 2


func _is_blocked(cell: Vector2i) -> bool:
	if not _in_playable(cell):
		return true
	return not carved.has(cell)


func _spike_kills(cell: Vector2i, move_dir: Vector2i) -> bool:
	if not spike_walls.has(cell):
		return false
	var danger: Vector2i = spike_walls[cell]
	return Vector2(move_dir).dot(Vector2(danger)) < -0.7


func _touches_wall() -> bool:
	for dir in DIRS:
		if _is_blocked(player + dir) or spike_walls.has(player + dir):
			return true
	return false


func _covers_paths() -> bool:
	var seen := {player: true}
	var stops := {player: true}
	var queue: Array[Vector2i] = [player]
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		for dir in DIRS:
			var cells := _safe_slide(pos, dir)
			if cells.is_empty():
				continue
			for cell in cells:
				seen[cell] = true
			var stop: Vector2i = cells[cells.size() - 1]
			if not stops.has(stop):
				stops[stop] = true
				queue.append(stop)
	for key in carved.keys():
		if not seen.has(key):
			return false
	return seen.has(head)


func _safe_slide(start: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var nxt := start + dir
	if _spike_kills(nxt, dir) or _is_blocked(nxt):
		return []
	var cells: Array[Vector2i] = []
	var pos := start
	while cells.size() < 80:
		nxt = pos + dir
		if _spike_kills(nxt, dir):
			return []
		if _is_blocked(nxt):
			return cells
		pos = nxt
		cells.append(pos)
	return []


func _dump_level() -> void:
	var top := mini(head.y, player.y) - 1
	var bottom := player.y + 2
	for y in range(top, bottom + 1):
		var line := ""
		for x in COLS:
			var cell := Vector2i(x, y)
			if cell == player:
				line += "@"
			elif cell == head:
				line += "H"
			elif timed_cells.has(cell):
				line += "t"
			elif int(carved.get(cell, 0)) == 2:
				line += "*"
			elif carved.has(cell):
				line += "."
			elif spike_walls.has(cell):
				line += "^"
			elif _shooter_cell(cell):
				line += "S"
			else:
				line += "#"
		print(line)


func _shooter_cell(cell: Vector2i) -> bool:
	for shooter in shooters:
		if shooter["cell"] == cell:
			return true
	return false


func _begin_slide(dir: Vector2i) -> void:
	if dir == Vector2i.ZERO or not alive:
		return
	if sliding or bumping:
		queued_dir = dir
		return
	if not _touches_wall():
		return
	var next_cell := player + dir
	if _spike_kills(next_cell, dir):
		slide_dir = dir
		_crash_into_spike()
		return
	if _is_blocked(next_cell):
		_bump(dir)
		return
	sliding = true
	slide_dir = dir
	trap_until = 0
	trail.clear()
	trail[player] = true
	hint_label.visible = false
	if dir.x != 0:
		player_sprite.flip_h = dir.x < 0
	_step_slide()


func _step_slide() -> void:
	if not alive:
		return
	var nxt := player + slide_dir
	if _spike_kills(nxt, slide_dir):
		_crash_into_spike()
		return
	if _is_blocked(nxt):
		_end_slide()
		return
	slide_tween = create_tween()
	slide_tween.tween_property(player_sprite, "position", _grid_to_world(nxt), STEP_TIME).set_trans(Tween.TRANS_LINEAR)
	slide_tween.tween_callback(_arrive.bind(nxt))


func _arrive(nxt: Vector2i) -> void:
	if not alive:
		return
	player = nxt
	player_sprite.position = _grid_to_world(player)
	trail[player] = true
	var kind := int(carved.get(player, 0))
	if kind == 1:
		carved[player] = 0
		chunks.take_dot(player)
		score += 10
		coin_sfx.play()
	elif kind == 2:
		carved[player] = 0
		chunks.take_dot(player)
		score += 50
		coin_sfx.play()
	if player.y < highest:
		var rows: int = highest - player.y
		score += rows * 2
		climbed += rows
		highest = player.y
		_extend_to(player.y - LOOKAHEAD)
	_pull_lava()
	if player.y >= lava_y:
		_die()
		return
	_step_slide()


func _end_slide() -> void:
	sliding = false
	player_sprite.position = _grid_to_world(player)
	var queued := queued_dir
	queued_dir = Vector2i.ZERO
	if queued != Vector2i.ZERO and queued != slide_dir and alive:
		_begin_slide(queued)
		return
	if timed_cells.has(player):
		trap_cell = player
		trap_until = Time.get_ticks_msec() + TRAP_DELAY_MS


func _crash_into_spike() -> void:
	if not alive:
		return
	sliding = true
	hint_label.visible = false
	if slide_dir.x != 0:
		player_sprite.flip_h = slide_dir.x < 0
	var tw := create_tween()
	slide_tween = tw
	var bump_pos := player_sprite.position + Vector2(slide_dir) * 4.0
	tw.tween_property(player_sprite, "position", bump_pos, 0.04)
	tw.tween_callback(_die)


func _bump(dir: Vector2i) -> void:
	if bump_tween and bump_tween.is_valid():
		bump_tween.kill()
	bumping = true
	if dir.x != 0:
		player_sprite.flip_h = dir.x < 0
	bump_sfx.play()
	_shake(2.0)
	var origin := _grid_to_world(player)
	player_sprite.position = origin
	bump_tween = create_tween()
	bump_tween.tween_property(player_sprite, "position", origin + Vector2(dir) * 3.0, 0.04)
	bump_tween.tween_property(player_sprite, "position", origin, 0.06)
	bump_tween.tween_callback(_end_bump)


func _end_bump() -> void:
	bumping = false
	player_sprite.position = _grid_to_world(player)
	var queued := queued_dir
	queued_dir = Vector2i.ZERO
	if queued != Vector2i.ZERO and queued != slide_dir and alive:
		_begin_slide(queued)


func _check_trap() -> void:
	if trap_until <= 0 or Time.get_ticks_msec() < trap_until:
		return
	trap_until = 0
	if player == trap_cell and not sliding and alive:
		_die()


func _update_hazards(delta: float) -> void:
	for shooter in shooters:
		shooter["wait"] = float(shooter["wait"]) - delta
		if float(shooter["wait"]) > 0.0:
			continue
		shooter["wait"] = shooter["interval"]
		var dir: Vector2i = shooter["dir"]
		var origin: Vector2i = shooter["cell"] + dir
		if carved.has(origin):
			bullets.append({"pos": _grid_to_world(origin), "dir": dir})
	var kept: Array[Dictionary] = []
	for bullet in bullets:
		var dir: Vector2i = bullet["dir"]
		var pos: Vector2 = bullet["pos"] + Vector2(dir) * BULLET_SPEED * delta
		var cell := Vector2i(floori(pos.x / float(TILE)), floori(pos.y / float(TILE)))
		if not carved.has(cell):
			continue
		if cell == player or cell == _sprite_cell():
			_die()
			return
		bullet["pos"] = pos
		kept.append(bullet)
	bullets = kept


func _sprite_cell() -> Vector2i:
	return Vector2i(
		floori(player_sprite.position.x / float(TILE)),
		floori(player_sprite.position.y / float(TILE))
	)


func _rise_lava(delta: float) -> void:
	if grace > 0.0:
		grace -= delta
		return
	lava_clock += delta
	var interval := maxf(0.22, 0.95 - float(climbed) * 0.008)
	if lava_clock < interval:
		return
	lava_clock = 0.0
	lava_y -= 1
	_cleanup_below()
	if _player_row() >= lava_y:
		_die()


func _pull_lava() -> void:
	var limit := player.y + MAX_LAVA_LAG
	if lava_y <= limit:
		return
	lava_y = limit
	_cleanup_below()
	if alive and _player_row() >= lava_y:
		_die()


func _animate_lava(delta: float) -> void:
	lava_anim += delta
	if lava_anim < 0.12:
		return
	lava_anim = 0.0
	lava_frame = 1 - lava_frame


func _cleanup_below() -> void:
	chunks.free_below(lava_y)
	var limit := lava_y + 6
	_erase_below(carved, limit)
	_erase_below(spike_walls, limit)
	_erase_below(timed_cells, limit)
	_erase_below(trail, limit)
	var kept_shooters: Array[Dictionary] = []
	for shooter in shooters:
		var cell: Vector2i = shooter["cell"]
		if cell.y <= limit:
			kept_shooters.append(shooter)
	shooters = kept_shooters
	var kept_bullets: Array[Dictionary] = []
	for bullet in bullets:
		var pos: Vector2 = bullet["pos"]
		if pos.y <= float(limit * TILE):
			kept_bullets.append(bullet)
	bullets = kept_bullets


func _erase_below(bag: Dictionary, limit: int) -> void:
	var drop: Array[Vector2i] = []
	for key in bag.keys():
		var cell := key as Vector2i
		if cell.y > limit:
			drop.append(cell)
	for cell in drop:
		bag.erase(cell)


func _player_row() -> int:
	return floori(player_sprite.position.y / float(TILE))


func _die() -> void:
	if not alive:
		return
	alive = false
	sliding = false
	bumping = false
	trap_until = 0
	bullets.clear()
	if slide_tween and slide_tween.is_valid():
		slide_tween.kill()
	if bump_tween and bump_tween.is_valid():
		bump_tween.kill()
	player_sprite.modulate = Color(1.0, 0.35, 0.65)
	die_sfx.play()
	_shake(5.0)
	if score > best:
		best = score
		_save_best()
	death_score.text = "%05d" % score
	death_root.visible = true
	hint_label.visible = false
	restart_at = Time.get_ticks_msec() + 450
	_update_hud()


func _restart() -> void:
	if restarting:
		return
	restarting = true
	get_tree().reload_current_scene()
	
func _exit_to_menu() -> void:
	if restarting:
		return
	restarting = true
	if score > best:
		best = score
		_save_best()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE * 0.5, cell.y * TILE + TILE * 0.5)


func _camera_target() -> Vector2:
	return Vector2(COLS * TILE * 0.5, player_sprite.position.y - CAMERA_LEAD)


func _update_camera(delta: float) -> void:
	var target := _camera_target()
	var blend := 1.0 - exp(-12.0 * delta)
	camera.position = camera.position.lerp(target, blend)


func _shake(amount: float) -> void:
	var tw := create_tween()
	tw.tween_property(camera, "offset", Vector2(amount, -amount * 0.5), 0.03)
	tw.tween_property(camera, "offset", Vector2(-amount * 0.6, amount * 0.4), 0.03)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.04)


func _dir_from_vector(delta: Vector2) -> Vector2i:
	if absf(delta.x) > absf(delta.y):
		return Vector2i(1 if delta.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if delta.y > 0.0 else -1)


func _dir_from_key(code: Key) -> Vector2i:
	match code:
		KEY_W, KEY_UP:
			return Vector2i.UP
		KEY_S, KEY_DOWN:
			return Vector2i.DOWN
		KEY_A, KEY_LEFT:
			return Vector2i.LEFT
		KEY_D, KEY_RIGHT:
			return Vector2i.RIGHT
		_:
			return Vector2i.ZERO


func _is_confirm(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_R]
	if event is InputEventScreenTouch and event.pressed:
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false


func _update_hud() -> void:
	if score_label == null:
		return
	score_label.text = "SCR %05d" % score
	best_label.text = "BEST %05d" % maxi(best, score)


func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("arcade", "best", 0))


func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("arcade", "best", best)
	cfg.save(SAVE_PATH)


func _build_ui() -> void:
	var mist := ColorRect.new()
	mist.color = Color(1, 1, 1, 1)
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/mist.gdshader")
	mist.material = material
	ui.add_child(mist)
	mist.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	score_label = _make_label("SCR 00000", 10, CYAN)
	score_label.position = Vector2(8, 6)
	ui.add_child(score_label)

	best_label = _make_label("BEST 00000", 10, MAGENTA)
	best_label.position = Vector2(96, 6)
	best_label.size = Vector2(104, 16)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(best_label)

	hint_label = _make_label("SWIPE OR ARROWS", 8, CYAN)
	hint_label.position = Vector2(0, 22)
	hint_label.size = Vector2(208, 14)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(hint_label)

	death_root = Control.new()
	death_root.visible = false
	death_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(death_root)
	death_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.06, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	center.add_child(box)

	box.add_child(_make_label("SIGNAL LOST", 16, MAGENTA))
	death_score = _make_label("00000", 14, GOLD)
	box.add_child(death_score)
	box.add_child(_make_label("TAP TO REBOOT", 8, CYAN))


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 2)
	return label


func _build_audio() -> void:
	coin_sfx = _make_player(preload("res://assets/sfx/coin.wav"), -2.0)
	bump_sfx = _make_player(preload("res://assets/sfx/bump.wav"), -6.0)
	die_sfx = _make_player(preload("res://assets/sfx/die.wav"), -4.0)


func _make_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var node := AudioStreamPlayer.new()
	node.stream = stream
	node.volume_db = volume_db
	add_child(node)
	return node
