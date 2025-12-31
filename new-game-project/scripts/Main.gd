extends Node2D

@onready var player: Player = $Player

func _ready():
	Game.player = player
	
	player.died.connect(_on_player_died)

	var spawn_counter = 0
	for e in $Enemies.get_children():
		if e is Enemy:
			e.setup(Game.adversaries, player)
			e.spawn_index = spawn_counter
			spawn_counter += 1

	Game.enemies = $Enemies.get_children()
	Game.adversaries.clear_adversaries_not_present()

func _on_player_died(respawn_pos: Vector2) -> void:
	var spawn_counter = 0
	for e in $Enemies.get_children():
		if e is Enemy:
			e.spawn_index = spawn_counter
			spawn_counter += 1
			e.on_player_died(respawn_pos)

	Game.enemies = $Enemies.get_children()
	Game.adversaries.clear_adversaries_not_present()