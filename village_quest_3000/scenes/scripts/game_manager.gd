extends Node2D

var singleton = Singleton.get_instance()
@export var game_seed: int

func _ready():
    singleton.game_seed.seed_value = game_seed
    singleton.game_seed.use_seed()
    print("Seed from singleton: ", singleton.game_seed.get_seed())