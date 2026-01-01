extends Node

signal player_registered(p)

var adversaries: AdversarySystem
var player: Player = null
var enemies: Array[Node] = []
var world_state: Dictionary = {}
var save_load_instance: SaveLoad

func _ready():
	randomize()
	adversaries = AdversarySystem.new()
	world_state = {}

	save_load_instance = SaveLoad.new()
	var loaded_data := save_load_instance.load()

	if loaded_data.is_empty():
		print("No save data found, starting new game.")
	else:
		print("Game loaded successfully.")


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_load_instance.save()

func _apply_player_save(pdict: Dictionary) -> void:
	if player != null:
		player.from_dict(pdict)

func register_player(p: Player) -> void:
	player = p
	emit_signal("player_registered", p)