extends Node2D

var mob_list = []
const GLOBAL_BULLET_DELAY = 1 # timer cycle
@onready var spawn_path: Path2D = $Spawner/SpawnPath

@onready var player = $Player

func _ready():
    mob_list.append(preload("res://scenes/mob.tscn"))

func get_player():
    return player

func spawn_mob():
    var mob = mob_list[0].instantiate()
    spawn_outside_entity(mob)

func spawn_trees():
    var tree = preload("res://scenes/tree.tscn").instantiate()
    spawn_outside_entity(tree)
    
func spawn_outside_entity(entity: Node):
    %PathFollow2D.progress_ratio = randf()
    entity.global_position = %PathFollow2D.global_position
    add_child(entity)
    

func _on_mob_spawn_timer_timeout() -> void:
    spawn_mob()
    spawn_trees()
