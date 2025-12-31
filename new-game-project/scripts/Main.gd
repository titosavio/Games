extends Node2D

func _ready():
	var player := $Player
	player.died.connect(_on_player_died)

	for e in $Enemies.get_children():
		if e is Enemy:
			e.setup(Game.adversaries, player)

func _on_player_died(respawn_pos: Vector2) -> void:
	for e in $Enemies.get_children():
		if e is Enemy:
			e.on_player_died(respawn_pos)
