# singleton.gd
class_name Singleton
extends Node

static var _instance: Singleton = null

@export var game_seed: GameSeed

static func get_instance() -> Singleton:
    if not _instance:
        _instance = Singleton.new()
    return _instance

func _init():
    if _instance != null:
        push_error("Singleton already exists. Use get_instance() to access it.")
        return

    _instance = self

    if not game_seed:
        game_seed = GameSeed.new()

func _ready() -> void:
    print("Singleton ready")