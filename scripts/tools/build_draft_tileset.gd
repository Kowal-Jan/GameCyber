extends SceneTree
## Синяя стена для ручного черновика. Рамка снята с правой нижней панели листа.

const TILE := 16
const TILESET_PATH := "res://assets/tiles/draft_tileset.tres"
const PREVIEW_PATH := "res://assets/tiles/wall_blue_preview.png"

const BODY := Color("0f0b0f")
const MID := Color("4b5bab")
const NEON := Color("4da6ff")
const GROOVE := Color("322947")


func _init() -> void:
	var tileset := _build_tileset()
	var err := ResourceSaver.save(tileset, TILESET_PATH)
	if err != OK:
		push_error("Тайлсет не сохранён: %s" % err)
	else:
		print("Синий тайлсет: ", TILESET_PATH)
	quit()


func _build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_terrain_set()
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tileset.add_terrain(0, 0)
	tileset.set_terrain_color(0, 0, NEON)
	tileset.set_terrain_name(0, 0, "Wall")
	var wall_image := _wall_image()
	var preview := wall_image.duplicate()
	preview.resize(256, 256, Image.INTERPOLATE_NEAREST)
	preview.save_png(ProjectSettings.globalize_path(PREVIEW_PATH))
	var walls := TileSetAtlasSource.new()
	walls.texture = ImageTexture.create_from_image(wall_image)
	walls.texture_region_size = Vector2i(TILE, TILE)
	for mask in 16:
		var coords := Vector2i(mask % 4, int(mask / 4.0))
		walls.create_tile(coords)
		var data := walls.get_tile_data(coords, 0)
		data.terrain_set = 0
		data.terrain = 0
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, 0 if (mask & 1) != 0 else -1)
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, 0 if (mask & 2) != 0 else -1)
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, 0 if (mask & 4) != 0 else -1)
		data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, 0 if (mask & 8) != 0 else -1)
	tileset.add_source(walls, 0)
	var dots := TileSetAtlasSource.new()
	dots.texture = ImageTexture.create_from_image(_dot_image())
	dots.texture_region_size = Vector2i(TILE, TILE)
	dots.create_tile(Vector2i(0, 0))
	dots.create_tile(Vector2i(1, 0))
	tileset.add_source(dots, 1)
	return tileset


func _wall_image() -> Image:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for mask in 16:
		var origin := Vector2i((mask % 4) * TILE, int(mask / 4.0) * TILE)
		for y in TILE:
			for x in TILE:
				image.set_pixel(origin.x + x, origin.y + y, _wall_pixel(x, y, mask))
	return image


func _wall_pixel(x: int, y: int, mask: int) -> Color:
	var dist := 99
	var along := 0
	if (mask & 1) == 0 and y < dist:
		dist = y
		along = x
	if (mask & 4) == 0 and TILE - 1 - y < dist:
		dist = TILE - 1 - y
		along = x
	if (mask & 8) == 0 and x < dist:
		dist = x
		along = y
	if (mask & 2) == 0 and TILE - 1 - x < dist:
		dist = TILE - 1 - x
		along = y
	if dist == 0:
		return MID
	if dist == 1 or dist == 2:
		return NEON if (along % 8) < 4 else MID
	if dist == 3:
		return GROOVE
	return BODY


func _dot_image() -> Image:
	var image := Image.create(32, TILE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.fill_rect(Rect2i(6, 6, 4, 4), Color("ffe14a"))
	var star := Color("fff6b0")
	image.fill_rect(Rect2i(16 + 6, 6, 4, 4), star)
	image.fill_rect(Rect2i(16 + 3, 7, 3, 2), star)
	image.fill_rect(Rect2i(16 + 10, 7, 3, 2), star)
	image.fill_rect(Rect2i(16 + 7, 3, 2, 3), star)
	image.fill_rect(Rect2i(16 + 7, 10, 2, 3), star)
	return image
