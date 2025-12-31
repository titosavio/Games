extends Node
class_name EnemyBrain

var enemy_owner: Enemy

enum State { PATROL, CHASE, INVESTIGATE, RETURN }
signal enter_return()

var state: State = State.PATROL
var last_state: State = State.PATROL

var chase_timeout := 2.0
var investigate_time := 2.0

var last_seen_pos: Vector2 = Vector2.ZERO
var last_seen_t := -999.0
var investigate_until := -999.0
var investigate_start_t := -999.0	

var patrol_speed_mult := 0.5

var sees: bool = false

func setup(o: Enemy) -> void:
	enemy_owner = o
	chase_timeout = enemy_owner.chase_timeout
	investigate_time = enemy_owner.investigate_time
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

	# Detecta entrada em INVESTIGATE e calcula arco
	if state == State.INVESTIGATE and last_state != State.INVESTIGATE:
		enemy_owner.nav.build_investigate_arc()
		investigate_start_t = _now()

	match intent.state:
		State.PATROL:
			speed_mult = patrol_speed_mult
			desired_point = enemy_owner.nav.patrol_target(
				enemy_owner.global_position,
				enemy_owner.spawn_pos,
				enemy_owner.motor.facing_dir,
			)
		State.CHASE:
			speed_mult = 1.0
			enemy_owner.nav_agent.target_position = enemy_owner.target.global_position
			desired_point = enemy_owner.nav_agent.get_next_path_position()
		State.INVESTIGATE:
			speed_mult = 0.75
			var progress: float = clamp((_now() - investigate_start_t) / investigate_time, 0.0, 1.0)
			var arrived := _has_arrived(last_seen_pos)
			if arrived:
				var look_pt = enemy_owner.nav.investigate_target(progress) # ponto no arco
				enemy_owner.motor.look_towards(look_pt)
				desired_point = enemy_owner.global_position # não anda
		State.RETURN:
			speed_mult = 0.8
			enemy_owner.nav_agent.target_position = enemy_owner.spawn_pos
			desired_point = enemy_owner.nav_agent.get_next_path_position()
			enemy_owner.nav_agent.debug_enabled = true
	return EnemyIntent.new(intent.state, desired_point, speed_mult)

	

func _tick() -> Intent:
	var now := Time.get_ticks_msec() / 1000.0
	var player_pos: Vector2= enemy_owner.target.global_position

	if state != last_state:
		print("[EnemyBrain] State changed from: %s to: %s" % [State.keys()[last_state], State.keys()[state]])
		last_state = state

	if sees:
		return Intent.new(State.CHASE, investigate_until, player_pos, true)

	match state:
		State.PATROL:
			return Intent.new(state, investigate_until, Vector2.ZERO, false)

		State.CHASE:
			# se nao ve mais o player, vai para investigar
			if (now - last_seen_t) > chase_timeout or enemy_owner.global_position.distance_to(last_seen_pos) < enemy_owner.shape_radius:
				investigate_start_t = now

				# ajuste para nao ficar andando em circulos
				if enemy_owner.global_position.distance_to(last_seen_pos) < enemy_owner.shape_radius:
					last_seen_pos = enemy_owner.global_position

				return Intent.new(State.INVESTIGATE, now + investigate_time, last_seen_pos, true)

			# continua a perseguir até ver o player ou timeout
			return Intent.new(state, investigate_until, last_seen_pos, true)

		State.INVESTIGATE:
			var arrived := _has_arrived(last_seen_pos)
			if now > investigate_until and arrived:
				emit_signal("enter_return")
				return Intent.new(State.RETURN, investigate_until, enemy_owner.spawn_pos, true)

			# enquanto não chegou no last_seen_pos, vai até lá
			if not arrived:
				return Intent.new(state, investigate_until, last_seen_pos, false)

			# chegou: fica no arco (update_intent decide o target), então não força movimento base
			return Intent.new(state, investigate_until, Vector2.ZERO, false)

		State.RETURN:
			# se chegou ao spawn, volta a patrulhar
			if enemy_owner.global_position.distance_to(enemy_owner.spawn_pos) < enemy_owner.shape_radius + 5.0:
				return Intent.new(State.PATROL, investigate_until, Vector2.ZERO, true)

			# continua a voltar ao spawn
			return Intent.new(state, investigate_until, enemy_owner.spawn_pos, false)

	# default fallback
	return Intent.new(state, investigate_until, enemy_owner.spawn_pos, false)

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _has_arrived(target: Vector2) -> bool:
	return enemy_owner.global_position.distance_to(target) < enemy_owner.shape_radius + 5.0