##============================================================================##
#  isometric_world.gd — Builds an isometric tile map at runtime                  #
#  Uses Kenney's Isometric Tiles Base PNGs                                       #
##============================================================================##

class_name IsometricWorld
extends Node2D

## Tile size in Kenney's isometric set: 128x64 (2:1 ratio)
const TILE_WIDTH: int = 128
const TILE_HEIGHT: int = 64

## How many tiles in each direction
@export var grid_width: int = 16
@export var grid_height: int = 16

## Tile palette: atlas source paths
const TILE_GRASS: int = 0
const TILE_DIRT: int = 1
const TILE_WATER: int = 2
const TILE_STONE: int = 3
const TILE_SAND: int = 4

## Internal state
var _tile_sprites: Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_world()


func _build_world() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	_tile_sprites.clear()
	
	# Create ground tiles
	for y in range(grid_height):
		for x in range(grid_width):
			_place_tile(x, y, _choose_ground_tile(x, y))
	
	# Add decorative trees/rocks using a subset of tiles
	for i in range(20):
		var x: int = _rng.randi_range(1, grid_width - 2)
		var y: int = _rng.randi_range(1, grid_height - 2)
		_place_decoration(x, y)


func _place_tile(x: int, y: int, tile_type: int) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = _get_tile_texture(tile_type)
	sprite.position = _grid_to_world(x, y)
	sprite.z_index = -10 + y  # Depth sort
	add_child(sprite)
	_tile_sprites.append(sprite)


func _place_decoration(x: int, y: int) -> void:
	# Use tile 50-100 range for trees/rocks (from Kenney's isometric set)
	var decoration_id: int = _rng.randi_range(50, 90)
	var sprite = Sprite2D.new()
	sprite.texture = _load_kenney_tile(decoration_id)
	sprite.position = _grid_to_world(x, y) - Vector2(0, 16)
	sprite.z_index = y  # Trees/rocks sort by row
	sprite.modulate = Color(1, 1, 1, 1)
	add_child(sprite)
	_tile_sprites.append(sprite)


func _grid_to_world(x: int, y: int) -> Vector2:
	# Convert grid coords to isometric screen coords
	# Standard 2:1 isometric projection
	var world_x: float = (x - y) * (TILE_WIDTH * 0.5)
	var world_y: float = (x + y) * (TILE_HEIGHT * 0.5)
	return Vector2(world_x, world_y)


func _choose_ground_tile(x: int, y: int) -> int:
	# Borders are stone, center is grass
	if x == 0 or y == 0 or x == grid_width - 1 or y == grid_height - 1:
		return TILE_STONE
	# Add some variation
	if _rng.randf() < 0.1:
		return TILE_DIRT
	if _rng.randf() < 0.05:
		return TILE_SAND
	return TILE_GRASS


func _get_tile_texture(tile_type: int) -> Texture2D:
	# Map to Kenney's landscapeTiles_XXX.png atlas indices
	# From Preview: 000=grass, 010=dirt, 020=stone, 030=water
	match tile_type:
		TILE_GRASS:
			return _load_kenney_tile(0)
		TILE_DIRT:
			return _load_kenney_tile(20)
		TILE_WATER:
			return _load_kenney_tile(40)
		TILE_STONE:
			return _load_kenney_tile(60)
		TILE_SAND:
			return _load_kenney_tile(80)
	return _load_kenney_tile(0)


var _tile_cache: Dictionary = {}

func _load_kenney_tile(idx: int) -> Texture2D:
	if _tile_cache.has(idx):
		return _tile_cache[idx]
	var path: String = "res://assets/isometric_tiles/landscapeTiles_%03d.png" % idx
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_tile_cache[idx] = tex
		return tex
	# Fallback to a placeholder
	return _get_placeholder_texture()


func _get_placeholder_texture() -> Texture2D:
	# Generate a simple colored rectangle as fallback
	var img: Image = Image.create(TILE_WIDTH, TILE_HEIGHT, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.6, 0.3, 1))  # Green grass color
	return ImageTexture.create_from_image(img)