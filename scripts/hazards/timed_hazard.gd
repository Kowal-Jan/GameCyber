@tool
extends Node2D
## Плита на полу. Если остановиться на ней и не уехать, она срабатывает.

const COLOR := Color("ffb03a")

@export var tile := Vector2i.ZERO:
	set(value):
		tile = value
		position = Vector2(value.x * 16 + 8, value.y * 16 + 8)
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-8, -8, 16, 2), COLOR)
	draw_rect(Rect2(-8, 6, 16, 2), COLOR)
	draw_rect(Rect2(-8, -8, 2, 16), COLOR)
	draw_rect(Rect2(6, -8, 2, 16), COLOR)


func register(host, origin: Vector2i) -> void:
	var world := origin + tile
	host.game.timed_cells[world] = true
	host.timed_cells.append(world)
