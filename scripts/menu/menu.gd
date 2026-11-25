extends Node2D

const SAVE_PATH := "user://best.cfg"
const MAGENTA := Color("ff3d9a")
const INK := Color("07060f")


func _ready() -> void:
	var label := Label.new()
	label.text = "BEST %05d" % _load_best()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", MAGENTA)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = Vector2(0, 108)
	label.size = Vector2(208, 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)


func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("arcade", "best", 0))
