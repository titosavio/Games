extends CharacterBody2D
class_name Enemy

enum State { PATROL, CHASE, INVESTIGATE, RETURN }
var state: State = State.PATROL

@export var enemy_id := ""
@export var base_speed := 45.0

@export var follow_radius := 220.0     # começa a seguir quando perto
@export var follow_angle := 90.0      # ângulo de visão
var num_cone_segments := 18
var sight_mask := 2  # 1: player, 2: paredes, 3: chao
var facing_dir := Vector2.RIGHT

@export var cone_is_visible := true  # mostra o cone de visão
@export var path_debug_visible := true
@export var stop_distance := 14.0      # para de grudar
@export var accel := 10.0              # “suavidade”

var speed := base_speed
var distance_to_target_at_respawn := 100
var adversary_system: AdversarySystem
var target: CharacterBody2D
var spawn_pos: Vector2

@export var patrol_step := 140.0          # tamanho do “passo” do caminho
@export var patrol_points := 4            # quantos waypoints manter
@export var patrol_reach_eps := 10.0
@export var patrol_speed_mult := 0.55
@export var nav_mask := 3                # colisão para navegação

@export var investigate_time := 2.0       # tempo procurando no último ponto visto
@export var chase_timeout := 3.0          # se ficar sem ver por isso, investiga
@export var return_reach_eps := 12.0

var path: Array[Vector2] = []
var path_i := 0

var last_seen_pos := Vector2.ZERO
var last_seen_t := -999.0
var investigate_until := -999.0


@onready var label_name: Label = $Label

func _ready():
	if enemy_id == "":
		enemy_id = str(get_instance_id())
		
	spawn_pos= global_position
	_build_patrol_path()

func _process(_delta):
	if cone_is_visible or path_debug_visible:
		queue_redraw()

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
	if sees:
		last_seen_pos = target.global_position
		last_seen_t = Time.get_ticks_msec() / 1000.0

	match state:
		State.PATROL:
			if sees:
				state = State.CHASE
			_patrol(delta)

		State.CHASE:
			if sees:
				_chase(delta)
			else:
				_move_towards(last_seen_pos, speed, delta)
				if _since(last_seen_t) > chase_timeout:
					state = State.INVESTIGATE
					investigate_until = _now() + investigate_time


		State.INVESTIGATE:
			if sees:
				state = State.CHASE
				_chase(delta)
			else:
				_investigate(delta)
				if _now() > investigate_until:
					state = State.RETURN

		State.RETURN:
			if sees:
				state = State.CHASE
				_chase(delta)
			else:
				_return_to_spawn(delta)

	move_and_slide()

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _since(t: float) -> float:
	return _now() - t


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
	var half_angle := deg_to_rad(follow_angle) / 2
	var dot := facing_dir.normalized().dot(dir)
	var ang := acos(clamp(dot, -1.0, 1.0))
	if ang > half_angle:
		return false

	# linha de visão (parede bloqueia)
	return has_line_of_sight(target.global_position)

func _get_view_mask(origin, world_point: Vector2) -> PhysicsRayQueryParameters2D:
	var q := PhysicsRayQueryParameters2D.create(origin, world_point)
	q.collision_mask = sight_mask
	q.exclude = [self]
	q.exclude += get_children()
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.hit_from_inside = true
	return q
	

func has_line_of_sight(world_point: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var origin := global_position + facing_dir.normalized() * 6.0

	var q := _get_view_mask(origin, world_point)

	var hit := space.intersect_ray(q)

	if hit.is_empty():
		return true

	return false


func _draw():
	_draw_cone()
	_draw_path()
	_draw_investigation_point()

func _draw_cone():
	if not cone_is_visible:
		return

	var half := deg_to_rad(follow_angle) * 0.5
	var forward := facing_dir.normalized()
	if forward.length() < 0.001:
		forward = Vector2.RIGHT

	var start_angle := atan2(forward.y, forward.x) - half
	var end_angle := atan2(forward.y, forward.x) + half

	var points := PackedVector2Array()
	points.append(Vector2.ZERO)

	var space := get_world_2d().direct_space_state

	for i in range(num_cone_segments + 1):
		var t := float(i) / float(num_cone_segments)
		var a: float = lerp(start_angle, end_angle, t)
		var dir := Vector2(cos(a), sin(a)).normalized()

		var from := global_position
		var to := global_position + dir * follow_radius

		var q := _get_view_mask(from, to)

		var hit := space.intersect_ray(q)

		var end_world := to
		if not hit.is_empty():
			end_world = hit["position"]

		points.append(to_local(end_world))

	draw_colored_polygon(points, Color(1, 1, 0, 0.2))
	for j in range(points.size() - 1):
		draw_line(points[j], points[j + 1], Color(1, 1, 0, 0.9), 2.0)
	draw_line(points[-1], Vector2.ZERO, Color(1, 1, 0, 0.9), 2.0)

func _draw_path():
	if not path_debug_visible or path.is_empty():
		return

	# linha começa no spawn
	var prev := to_local(spawn_pos)

	for i in range(path.size()):
		var p := to_local(path[i])
		draw_line(prev, p, Color(0, 1, 1, 0.9), 2.0)
		prev = p

	# marca o waypoint atual
	var idx: int = clamp(path_i, 0, path.size() - 1)
	draw_circle(to_local(path[idx]), 5.0, Color(1, 0.2, 0.2, 0.9))

func _draw_investigation_point():
	if state == State.INVESTIGATE and not last_seen_pos == Vector2.ZERO:
		draw_circle(to_local(last_seen_pos), 6.0, Color(1, 0, 0, 0.7))
	if state == State.CHASE and can_see_target() == false:
		draw_circle(to_local(last_seen_pos), 4.0, Color(1, 1, 0, 0.7))


func _build_patrol_path():
	path.clear()
	path_i = 0

	var cur := spawn_pos
	var dir := facing_dir
	if dir.length() < 0.01:
		dir = Vector2.RIGHT

	for _k in range(patrol_points):
		var next := _pick_reachable_point(cur, dir)
		path.append(next)
		dir = (next - cur).normalized()
		cur = next
	
	# make return path
	for i in range(path.size() - 2, -1, -1):
		path.append(path[i])
	path.append(spawn_pos)


func _pick_reachable_point(from: Vector2, preferred_dir: Vector2) -> Vector2:
	var tries = 10
	var best := from
	var best_dist := 0.0

	for i in range(tries):
		var jitter := deg_to_rad(randf_range(-70.0, 70.0))
		var dir := preferred_dir.rotated(jitter).normalized()
		var candidate := from + dir * patrol_step

		var hit := _ray_hit(from, candidate)
		var endp: Vector2 = candidate if hit.is_empty() else (hit["position"] - dir * 10.0)
		var d := from.distance_to(endp)

		if d > best_dist:
			best_dist = d
			best = endp

	# se nada presta, anda um pouquinho aleatório pra destravar
	if best_dist < 20.0:
		var dir2 := Vector2.RIGHT.rotated(randf() * TAU)
		return from + dir2 * 40.0

	return best
	
func _ray_hit(from: Vector2, to: Vector2, mask_to_check: int = nav_mask) -> Dictionary:
	# checks for collision along the ray
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = mask_to_check
	q.exclude = [self, $KillZone]
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.hit_from_inside = true
	return space.intersect_ray(q)

func _patrol(delta):
	if path.is_empty():
		_build_patrol_path()

	var target_pt := path[path_i]
	_move_towards(target_pt, speed * patrol_speed_mult, delta)

	if global_position.distance_to(target_pt) <= patrol_reach_eps:
		path_i += 1
		if path_i >= path.size():
			# gera um novo caminho a partir de onde está (mapa desconhecido)
			spawn_pos = spawn_pos # mantém spawn real
			_build_patrol_path()

func _chase(delta):
	if not has_line_of_sight(target.global_position):
		state = State.INVESTIGATE
		investigate_until = _now() + investigate_time
		return
	_move_towards(target.global_position, speed, delta)

func _investigate(delta):
	_move_towards(last_seen_pos, speed * 0.75, delta)

func _return_to_spawn(delta):
	_move_towards(spawn_pos, speed * 0.8, delta)
	if global_position.distance_to(spawn_pos) <= return_reach_eps:
		state = State.PATROL
		_build_patrol_path()

func _move_towards(point: Vector2, move_speed: float, delta: float):
	var v := point - global_position
	var dist := v.length()
	if dist < 0.001:
		velocity = velocity.lerp(Vector2.ZERO, accel * delta)
		return

	facing_dir = v / dist
	var desired := facing_dir * move_speed
	velocity = velocity.lerp(desired, accel * delta)
	$Sprite2D.flip_h = facing_dir.x < 0
