extends CharacterBody2D
class_name Enemy

@export var enemy_id := ""
@export var base_speed := 45.0
@export var accel := 10.0

@export var follow_radius := 220.0
@export var follow_angle := 90.0

@export var sight_mask := 6
@export var nav_mask := 6 # 2 e 3 (ground + walls)

@export var patrol_step := 140.0
@export var patrol_points := 4
@export var patrol_reach_eps := 10.0
@export var patrol_speed_mult := 0.55

@export var investigate_time := 2.0
@export var chase_timeout := 1.0
@export var return_reach_eps := 12.0
@export var return_points_max := 8

@export var spawn_index := 0
@export var distance_to_target_at_respawn := 100

@export var cone_is_visible := true
@export var path_debug_visible := true

var speed := base_speed
var spawn_pos: Vector2
var points_per_direction_change := 12

var adversary_system: AdversarySystem
var target: CharacterBody2D

var colissionShape: CollisionShape2D
var shape_radius := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var label_name: Label = $Label

@onready var vision: EnemyVision = $Logic/Vision
@onready var nav: EnemyNavigator = $Logic/Navigator
@onready var brain: EnemyBrain = $Logic/Brain
@onready var motor: EnemyMotor = $Logic/Motor
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _ready():
	spawn_pos = global_position

	# id estável por spawn (room + pos + index)
	var room_id := "unknown_room"
	if get_parent() != null and get_parent().get("room_id") != null:
		room_id = str(get_parent().get("room_id"))

	if enemy_id == "":
		var key := "enemy:%s:%d:%d:%d" % [room_id, int(spawn_pos.x), int(spawn_pos.y), int(spawn_index)]
		enemy_id = "E_%s" % hash(key)

	# setup módulos (target entra depois no setup())
	nav.setup(self, nav_mask, patrol_step, patrol_points, patrol_reach_eps, return_reach_eps, return_points_max)
	nav.build_patrol_path(spawn_pos, motor.facing_dir)

	brain.setup(self)
	vision.setup(self)

	motor.setup(self, accel)
	
	nav_agent.path_desired_distance = 8.0
	nav_agent.target_desired_distance = 10.0
	nav_agent.radius = shape_radius / 2.0 + 5.0
	nav_agent.avoidance_enabled = true
	nav_agent.debug_enabled = path_debug_visible

func setup(system: AdversarySystem, player: CharacterBody2D) -> void:
	adversary_system = system
	target = player

	colissionShape = get_node_or_null("CollisionShape2D")
	if colissionShape != null and colissionShape.shape is CircleShape2D:
		shape_radius = colissionShape.shape.radius
	elif colissionShape != null and colissionShape.shape is RectangleShape2D:
		shape_radius = max(colissionShape.shape.extents.x, colissionShape.shape.extents.y)


	adversary_system.get_or_create(enemy_id)
	_apply_stats()


func _process(_delta):
	if cone_is_visible or path_debug_visible:
		queue_redraw()

func _physics_process(delta):
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var intent := brain.update_intent()
	var desired_point := intent.desired_point
	var speed_mult := intent.speed_mult

	_move_towards(desired_point, speed * speed_mult, delta)
	move_and_slide()

func _apply_stats():
	if adversary_system == null:
		return
	var data = adversary_system.get_or_create(enemy_id)
	speed = base_speed + float(data.rank - 1) * 10.0
	label_name.text = data.full_name

func on_player_killed(context: String):
	if adversary_system == null:
		return
	adversary_system.register_kill(enemy_id, context)
	_apply_stats()

func on_player_died(player_pos: Vector2) -> void:
	velocity = Vector2.ZERO
	nav.reset_to_spawn()
	var d := global_position.distance_to(player_pos)
	if d < distance_to_target_at_respawn:
		global_position += (global_position - player_pos).normalized() * (distance_to_target_at_respawn - d)

func _move_towards(point: Vector2, move_speed: float, delta: float):
	motor.move_towards(point, move_speed, delta)
	sprite.flip_h = motor.facing_dir.x < 0

func _draw():
	if cone_is_visible:
		vision.draw_cone()
	if path_debug_visible:
		nav.draw_path(self, global_position, brain.state)
	if brain.state == brain.State.INVESTIGATE and brain.last_seen_pos != Vector2.ZERO:
		draw_circle(to_local(brain.last_seen_pos), 6.0, Color(1, 0, 0, 0.7))
	if brain.state == brain.State.CHASE and not vision.can_see_target():
		draw_circle(to_local(brain.last_seen_pos), 4.0, Color(1, 1, 0, 0.7))
		
