extends Control

var game_seed
# var island_size = Vector2(200, 200)  # Size of the island

signal map_values_changed

@export var frequency = 0.05:
	set(value):
		frequency = value
		map_values_changed.emit()

@export var fractal_octaves = 4:
	set(value):
		fractal_octaves = value
		map_values_changed.emit()

@export var fractal_lacunarity = 2.0:
	set(value):
		fractal_lacunarity = value
		map_values_changed.emit()

@export var fractal_gain = 0.5:
	set(value):
		fractal_gain = value
		map_values_changed.emit()

@export var island_size: Vector2 = Vector2(200, 200):
	set(value):
		island_size = value
		map_values_changed.emit()

@export var pixel_size = 1:
	set(value):
		pixel_size = value
		map_values_changed.emit()

var noise = FastNoiseLite.new()

var island_tilemap: TileMapLayer

func init_vars() -> void:
	if not frequency:
		frequency = 0.05
	if not fractal_octaves:
		fractal_octaves = 4
	if not fractal_lacunarity:
		fractal_lacunarity = 2.0
	if not fractal_gain:
		fractal_gain = 0.5
	if not island_size:
		island_size = Vector2(100, 100)
	if not pixel_size:
		pixel_size = 1

func _ready():
	var singleton = Singleton.get_instance()
	game_seed = singleton.game_seed.get_seed()
	init_vars()
	initialize_noise()
	island_tilemap = $TileMapLayer
	queue_redraw()
	connect("map_values_changed", Callable(self, "_on_map_values_changed"))

func _draw():
	draw_island()

func initialize_noise():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = game_seed  # Use the seed value from GameSeed
	noise.frequency = frequency or 0.05  # Similar to period, adjust as needed
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM  # Fractal type
	noise.fractal_octaves = fractal_octaves or 4  # Number of octaves
	noise.fractal_lacunarity = fractal_lacunarity or 2.0  # Adjust as needed
	noise.fractal_gain = fractal_gain or 0.5  # Similar to persistence, adjust as needed

func update_noise():
	noise.seed = game_seed
	noise.frequency = frequency
	noise.fractal_octaves = fractal_octaves
	noise.fractal_lacunarity = fractal_lacunarity
	noise.fractal_gain = fractal_gain
func draw_island():
	var half_width = island_size.x / 2
	var half_height = island_size.y / 2

	update_noise()
	island_tilemap.clear()

	var half_pixel_size = pixel_size / 2

	for x in range(island_size.x):
		for y in range(island_size.y):
			var nx = (x - half_width) / ( half_width * pixel_size)	
			var ny = (y - half_height) / ( half_height * pixel_size)
			
			var height_value = noise.get_noise_2d(nx, ny)
			var tile_id = 1 if height_value < 0.0 else 2  # 0 for sand, 1 for water


			
			island_tilemap.set_cell(Vector2i(x, y), 0, Vector2i(tile_id, 0))

func _on_map_values_changed():
	print("Map values changed")
	draw_island()
	queue_redraw()

