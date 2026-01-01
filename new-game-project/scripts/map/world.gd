extends Node2D

@onready var gen: BSPMapGenerator = $MapGenerator
@onready var builder: MapBuilder = $MapBuilder
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")

@export var _seed: int = 0

func build_world(player: Player) -> void:
	var shape = player.get_node("CollisionShape2D").shape
	var width_cells := int(shape.size.x * 10 / 32 * 12)
	var height_cells := int(shape.size.y * 10 / 32 * 8)
	var cell_size := int(max(shape.size.x, shape.size.y)) + 32

	var data := gen.generate(
		width_cells, height_cells, cell_size,
		_seed,
		14, 5,
		2,
		Vector2i(8, 8)
	)
	builder.rebuild(data)

	player.global_position = data.cell_to_world(data.start_cell)
	player.set_spawn_position(data.cell_to_world(data.start_cell))
	
	var sys: AdversarySystem = Game.adversaries if Game.has_method("get") else null
	
	spawner.spawn_enemies(data, self, player, sys, enemy_scene)
	
func _ready() -> void:
	Game.player_registered.connect(
		func(player):
			build_world(player),
		CONNECT_ONE_SHOT
	)
