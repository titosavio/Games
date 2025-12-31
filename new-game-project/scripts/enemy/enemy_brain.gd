extends Node
class_name EnemyBrain

var enemy_owner: Enemy

var chase_timeout := 2.0
var investigate_time := 2.0

func setup(o: Enemy, chase_timeout_val: float, investigate_time_val: float) -> void:
	enemy_owner = o
	chase_timeout = chase_timeout_val
	investigate_time = investigate_time_val

class Intent:
	var state: Enemy.State
	var investigate_until: float
	var move_target: Vector2
	var clear_nav_path: bool

	func _init(s: Enemy.State, iu: float, mt: Vector2, clear_path := false):
		state = s
		investigate_until = iu
		move_target = mt
		clear_nav_path = clear_path

func tick(
	state: Enemy.State,
	sees: bool,
	last_seen_pos: Vector2,
	last_seen_t: float,
	investigate_until: float,
	player_pos: Vector2,
	spawn_pos: Vector2
) -> Intent:
	var now := Time.get_ticks_msec() / 1000.0

	if sees:
		return Intent.new(Enemy.State.CHASE, investigate_until, player_pos, true)

	match state:
		Enemy.State.PATROL:
			return Intent.new(state, investigate_until, Vector2.ZERO, false)

		Enemy.State.CHASE:
			# NÃO vê: vai no ÚLTIMO ponto visto (isso mata o "seguir atrás da parede")
			if (now - last_seen_t) > chase_timeout:
				return Intent.new(Enemy.State.INVESTIGATE, now + investigate_time, last_seen_pos, true)

			return Intent.new(state, investigate_until, last_seen_pos, true)

		Enemy.State.INVESTIGATE:
			if now > investigate_until:
				# ao entrar em RETURN, limpa path e deixa o Navigator decidir
				return Intent.new(Enemy.State.RETURN, investigate_until, spawn_pos, true)

			# investiga sempre no last_seen_pos
			return Intent.new(state, investigate_until, last_seen_pos, false)

		Enemy.State.RETURN:
			# return vai pro spawn (Navigator pode trocar pra waypoints se bloqueado)
			return Intent.new(state, investigate_until, spawn_pos, false)

	return Intent.new(state, investigate_until, spawn_pos, false)
