extends CharacterBody2D
class_name Enemy

@export var enemy_id := ""
@export var base_speed := 45.0

var speed := 45.0
var adversary_system: AdversarySystem

@onready var label_name: Label = $Label

func _ready():
    if enemy_id == "":
        enemy_id = str(get_instance_id())

func setup(system: AdversarySystem) -> void:
    adversary_system = system
    _apply_stats()

func _apply_stats():
    if adversary_system == null:
        return
    var data = adversary_system.get_or_create(enemy_id)
    speed = base_speed + float(data.rank - 1) * 10.0
    set_label_name()

func on_player_killed(context: String):
    if adversary_system == null:
        return
    adversary_system.register_kill(enemy_id, context)
    _apply_stats()

func set_label_name():
    if adversary_system == null:
        return

    var data = adversary_system.get_or_create(enemy_id)
    label_name.text = data.full_name
