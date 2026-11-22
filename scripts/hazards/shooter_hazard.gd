@tool
extends Node2D
## Турель в стене. Пуля появляется в соседней проходимой клетке.

const BODY := Color("ff3d9a")
const BARREL := Color("3df0ff")

@export var tile := Vector2i.ZERO:
	set(value):
		tile = value
		position = Vector2(value.x * 16 + 8, value.y * 16 + 8)
		queue_redraw()
@export var direction := Vector2i.LEFT:
	set(value):
		direction = value
		queue_redraw()
@export var interval := 1.9


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-5, -5, 10, 10), BODY)
	if direction == Vector2i.ZERO:
		return
	var forward := Vector2(direction)
	var size := Vector2(7, 4) if direction.x != 0 else Vector2(4, 7)
	draw_rect(Rect2(forward * 3.0 - size * 0.5, size), BARREL)


func register(host, origin: Vector2i) -> void:
	var world := origin + tile
	host.game.shooters.append({
		"cell": world,
		"dir": direction,
		"wait": 0.7 + randf() * 0.6,
		"interval": interval,
	})
	host.shooter_cells.append(world)
