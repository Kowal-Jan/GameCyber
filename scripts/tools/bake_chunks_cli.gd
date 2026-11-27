extends SceneTree
## Запекает чанки из командной строки: godot --headless -s res://scripts/tools/bake_chunks_cli.gd


func _init() -> void:
	# var baker = load("res://scripts/tools/chunk_baker.gd").new()
	# baker.bake_all()
	# quit(0 if baker.bake_ok else 1)
	push_error("Автогенерация чанков отключена.")
	quit(0)
