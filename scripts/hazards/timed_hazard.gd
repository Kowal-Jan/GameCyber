@tool
extends Node2D
## Плита на полу. Если остановиться на ней и не уехать, она срабатывает.

const COLOR := Color("ffb03a")

const TILE := 16

@export var tile := Vector2i.ZERO:
	set(value):
		tile = value
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
	draw_rect(Rect2(-8, -8, 16, 2), COLOR)
	draw_rect(Rect2(-8, 6, 16, 2), COLOR)
	draw_rect(Rect2(-8, -8, 2, 16), COLOR)
	draw_rect(Rect2(6, -8, 2, 16), COLOR)


func register(host, origin: Vector2i) -> void:
	_adopt_position()
	var world := origin + tile
	host.game.timed_cells[world] = true
	host.timed_cells.append(world)
