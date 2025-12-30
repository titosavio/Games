extends CharacterBody2D
class_name Enemy

@export var enemy_id := ""
@export var base_speed := 45.0

@export var follow_radius := 220.0	 # começa a seguir quando perto
@export var stop_distance := 14.0	  # para de grudar
@export var accel := 10.0			  # “suavidade”

var speed := 45.0
var distance_to_target_at_respawn := 100
var adversary_system: AdversarySystem
var target: CharacterBody2D
var spawn_pos: Vector2

@onready var label_name: Label = $Label

func _ready():
    if enemy_id == "":
        enemy_id = str(get_instance_id())
        
    spawn_pos= global_position

func setup(system: AdversarySystem, player: CharacterBody2D) -> void:
    adversary_system = system
    target = player
    _apply_stats()

func _physics_process(delta):
    if target == null:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    var to_target := target.global_position - global_position
    var dist := to_target.length()

    if dist > follow_radius:
        # fora do raio: para
        velocity = velocity.lerp(Vector2.ZERO, accel * delta)
    elif dist <= stop_distance:
        # chegou perto: para
        velocity = velocity.lerp(Vector2.ZERO, accel * delta)
    else:
        var dir := to_target / dist
        var desired := dir * speed
        velocity = velocity.lerp(desired, accel * delta)
        $Sprite2D.flip_h = dir.x < 0

    move_and_slide()


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

func on_player_respawned(player_pos: Vector2) -> void:
    velocity = Vector2.ZERO
    print("Player respawned at %s, enemy %s at %s" % [player_pos, enemy_id, global_position])
    var d := global_position.distance_to(player_pos)
    if d < distance_to_target_at_respawn:
        global_position += (global_position - player_pos).normalized() * (distance_to_target_at_respawn - d)
        print("Enemy %s repositioned to %s after player respawn." % [enemy_id, global_position])
