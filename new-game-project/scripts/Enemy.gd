extends CharacterBody2D
class_name Enemy

@export var enemy_id := ""
@export var base_speed := 45.0

@export var follow_radius := 220.0     # começa a seguir quando perto
@export var follow_angle := 90.0      # ângulo de visão
var num_cone_segments := 18
var vision_collision_mask := 2  # 1: player, 2: paredes, 3: chao
var facing_dir := Vector2.RIGHT

@export var cone_is_visible := true  # mostra o cone de visão
@export var stop_distance := 14.0      # para de grudar
@export var accel := 10.0              # “suavidade”

var speed := base_speed
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
	var sees := can_see_target()

	if not sees:
		velocity = velocity.lerp(Vector2.ZERO, accel * delta)
		return
		
	var to_target := target.global_position - global_position
	var dist := to_target.length()

	if dist <= stop_distance:
		# chegou perto: para
		velocity = velocity.lerp(Vector2.ZERO, accel * delta)
	else:
		facing_dir = to_target / dist
		var desired := facing_dir * base_speed
		velocity = velocity.lerp(desired, accel * delta)
		$Sprite2D.flip_h = facing_dir.x < 0

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

func can_see_target() -> bool:
	if target == null:
		return false

	var to_target := target.global_position - global_position
	var dist := to_target.length()
	if dist > follow_radius:
		return false
	if dist < 0.001:
		return true

	var dir := to_target / dist

	# cone (ângulo)
	var half_angle := deg_to_rad(follow_angle) * 0.5
	var dot := facing_dir.normalized().dot(dir)
	var ang := acos(clamp(dot, -1.0, 1.0))
	if ang > half_angle:
		return false

	# linha de visão (parede bloqueia)
	return has_line_of_sight(target.global_position)

func has_line_of_sight(world_point: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, world_point)
	q.collision_mask = vision_collision_mask
	q.exclude = [self] # evita acertar o próprio inimigo

	var hit := space.intersect_ray(q)
	# se não bateu em nada, visão livre
	return hit.is_empty()
