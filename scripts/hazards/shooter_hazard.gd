@tool
extends Node2D
## Турель в стене. Пуля появляется в соседней проходимой клетке.

const BODY := Color("ff3d9a")
const BARREL := Color("3df0ff")

const TILE := 16

@export var tile := Vector2i.ZERO:
	set(value):
		tile = value
		queue_redraw()
@export var direction := Vector2i.LEFT:
	set(value):
		direction = value
		queue_redraw()
@export var interval := 1.9


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
	draw_rect(Rect2(-5, -5, 10, 10), BODY)
	if direction == Vector2i.ZERO:
		return
	var forward := Vector2(direction)
	var size := Vector2(7, 4) if direction.x != 0 else Vector2(4, 7)
	draw_rect(Rect2(forward * 3.0 - size * 0.5, size), BARREL)


func register(host, origin: Vector2i) -> void:
	_adopt_position()
	var world := origin + tile
	if not host.game.carved.has(world + direction):
		for dir in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if host.game.carved.has(world + dir):
				direction = dir
				break
	host.game.shooters.append({
		"cell": world,
		"dir": direction,
		"wait": 0.7 + randf() * 0.6,
		"interval": interval,
	})
	host.shooter_cells.append(world)
