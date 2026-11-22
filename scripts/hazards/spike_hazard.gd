@tool
extends Node2D
## Шип стоит на клетке стены. Остриё смотрит в коридор, в сторону direction.

const COLOR := Color("b8fff4")

@export var tile := Vector2i.ZERO:
	set(value):
		tile = value
		position = Vector2(value.x * 16 + 8, value.y * 16 + 8)
		queue_redraw()
@export var direction := Vector2i.DOWN:
	set(value):
		direction = value
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if direction == Vector2i.ZERO:
		return
	var forward := Vector2(direction)
	var side := Vector2(-forward.y, forward.x)
	var face := forward * 8.0
	for index in 3:
		var along := (float(index) - 1.0) * 5.0
		var left := face + side * (along - 2.0)
		var right := face + side * (along + 2.0)
		var tip := face + forward * 7.0 + side * along
		draw_colored_polygon(PackedVector2Array([left, right, tip]), COLOR)


func register(host, origin: Vector2i) -> void:
	var world := origin + tile
	host.game.spike_walls[world] = direction
	host.spike_cells.append(world)
