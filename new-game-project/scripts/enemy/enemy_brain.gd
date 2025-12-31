extends Node
class_name EnemyBrain

var enemy_owner: Enemy

enum State { PATROL, CHASE, INVESTIGATE, RETURN }

var state: State = State.PATROL
var last_state: State = State.PATROL

var chase_timeout := 2.0
var investigate_time := 2.0

var last_seen_pos: Vector2 = Vector2.ZERO
var last_seen_t := -999.0
var investigate_until := -999.0

var patrol_speed_mult := 0.5

var sees: bool = false

func setup(o: Enemy, chase_timeout_val: float, investigate_time_val: float) -> void:
	enemy_owner = o
	chase_timeout = chase_timeout_val
	investigate_time = investigate_time_val
	last_state = State.PATROL

	patrol_speed_mult = enemy_owner.patrol_speed_mult

class Intent:
	var state: State
	var investigate_until: float
	var move_target: Vector2
	var clear_nav_path: bool

	func _init(s: State, iu: float, mt: Vector2, clear_path := false):
		state = s
		investigate_until = iu
		move_target = mt
		clear_nav_path = clear_path

class EnemyIntent:
	var state: State
	var desired_point: Vector2
	var speed_mult: float

	func _init(s: State, dp: Vector2, sm: float):
		state = s
		desired_point = dp
		speed_mult = sm

func update_intent() -> EnemyIntent:
	sees = enemy_owner.vision.can_see_target()
	if sees:
		last_seen_pos = enemy_owner.target.global_position
		last_seen_t = _now()

	var intent := _tick()
	state = intent.state
	investigate_until = intent.investigate_until

	var desired_point := intent.move_target
	var speed_mult := 1.0

	if intent.clear_nav_path:
		enemy_owner.nav.clear_path()

	match state:
		State.PATROL:
			speed_mult = patrol_speed_mult
			desired_point = enemy_owner.nav.patrol_target(
				enemy_owner.global_position,
				enemy_owner.spawn_pos,
				enemy_owner.motor.facing_dir,
				)

		State.CHASE:
			speed_mult = 1.0

		State.INVESTIGATE:
			speed_mult = 0.75

		State.RETURN:
			speed_mult = 0.8
			desired_point = enemy_owner.nav.return_target(
				enemy_owner.global_position,
				enemy_owner.spawn_pos,
			)

	return EnemyIntent.new(state, desired_point, speed_mult)

	

func _tick() -> Intent:
	var now := Time.get_ticks_msec() / 1000.0
	var player_pos := enemy_owner.target.global_position

	if state != last_state:
		print("[EnemyBrain] State changed from: %s to: %s" % [State.keys()[last_state], State.keys()[state]])
		last_state = state

	if sees:
		return Intent.new(State.CHASE, investigate_until, player_pos, true)

	match state:
		State.PATROL:
			return Intent.new(state, investigate_until, Vector2.ZERO, false)

		State.CHASE:
			if (now - last_seen_t) > chase_timeout:
				return Intent.new(State.INVESTIGATE, now + investigate_time, last_seen_pos, true)

			return Intent.new(state, investigate_until, last_seen_pos, true)

		State.INVESTIGATE:
			var colissionShape := enemy_owner.get_node_or_null("CollisionShape2D")
			var shape_radius := 0.0
			if colissionShape != null and colissionShape.shape is CircleShape2D:
				shape_radius = colissionShape.shape.radius
			elif colissionShape != null and colissionShape.shape is RectangleShape2D:
				shape_radius = max(colissionShape.shape.extents.x, colissionShape.shape.extents.y)

			if enemy_owner.global_position.distance_to(last_seen_pos) < shape_radius + 5.0:
				return Intent.new(State.RETURN, investigate_until, enemy_owner.global_position, false)

			if now > investigate_until:
				return Intent.new(State.RETURN, investigate_until, enemy_owner.spawn_pos, true)

			# investiga sempre no last_seen_pos
			return Intent.new(state, investigate_until, last_seen_pos, false)

		State.RETURN:
			# return vai pro spawn (Navigator pode trocar pra waypoints se bloqueado)
			return Intent.new(state, investigate_until, enemy_owner.spawn_pos, false)

	return Intent.new(state, investigate_until, enemy_owner.spawn_pos, false)

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0