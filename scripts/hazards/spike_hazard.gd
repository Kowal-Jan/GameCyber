@tool
extends Node2D
## Шип стоит на клетке стены. Остриё смотрит в коридор, в сторону direction.

const COLOR := Color("ff3d9a")
const TILE := 16

@export var tile := Vector2i.ZERO:
	set(value):
		tile = value
		queue_redraw()
@export var direction := Vector2i.DOWN:
	set(value):
		direction = value
		queue_redraw()


func _ready() -> void:
	set_notify_transform(true)
	_adopt_position()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_adopt_position()


func _adopt_position() -> void:
	var cell := Vector2i(floori(position.x / float(TILE)), floori(position.y / float(TILE)))
	var snapped := Vector2(cell.x * TILE + 8, cell.y * TILE + 8)
	if position.distance_squared_to(snapped) > 0.1:
		position = snapped
	if cell != tile:
		tile = cell


func _draw() -> void:
	if direction == Vector2i.ZERO:
		return
	var forward := Vector2(direction)
	var side := Vector2(-forward.y, forward.x)
	var face := forward * 8.0
	var points := PackedVector2Array()
	var bends := 10
	var count := bends + 2
	for step in count:
		var along := (float(step) / float(count - 1) - 0.5) * 16.0
		var poke := 1.0 if step % 2 == 0 else 4.0
		points.append(face + side * along + forward * poke)
	draw_polyline(points, COLOR, 1.0, false)


func register(host, origin: Vector2i) -> void:
	_adopt_position()
	if direction == Vector2i.ZERO:
		return
	var cell := tile
	var danger := cell
	var walls := host.get_node_or_null("WallsLayer") as TileMapLayer
	if walls != null and walls.get_cell_source_id(cell) != -1:
		var ahead := cell + direction
		if ahead.x < 0 or ahead.x > 12 or walls.get_cell_source_id(ahead) != -1:
			return
		danger = ahead
	var world := origin + danger
	if not host.game.spike_walls.has(world):
		host.game.spike_walls[world] = []
	var dirs: Array = host.game.spike_walls[world]
	if not dirs.has(direction):
		dirs.append(direction)
	host.spike_cells.append(world)
