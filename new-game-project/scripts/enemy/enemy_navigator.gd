extends Node
class_name EnemyNavigator

var enemy_owner: Enemy
var nav_mask := 3

var patrol_step := 140.0
var patrol_points := 4
var patrol_reach_eps := 10.0

var return_reach_eps := 12.0
var return_points_max := 8

# histerese do retorno
var return_blocked_frames := 0
var return_clear_frames := 0
const RETURN_CONFIRM_FRAMES := 6

var path: Array[Vector2] = []
var path_i := 0

# Arco de investigação
var arc_degrees := 90.0
var investigate_arc: Array[Vector2] = []
var investigate_arc_i := 0

var path_line_color: Color = Color(0, 1, 1, 0.9)
var path_point_color: Color = Color(1, 0.2, 0.2, 0.9)

func setup(
	o: Enemy,
	nav_mask_val: int,
	patrol_step_val: float,
	patrol_points_val: int,
	patrol_reach_eps_val: float,
	return_reach_eps_val: float,
	return_points_max_val: int
) -> void:
	enemy_owner = o
	nav_mask = nav_mask_val

	patrol_step = patrol_step_val
	patrol_points = patrol_points_val
	patrol_reach_eps = patrol_reach_eps_val

	return_reach_eps = return_reach_eps_val
	return_points_max = return_points_max_val

func patrol_target(cur_pos: Vector2, spawn_pos: Vector2, facing_dir: Vector2) -> Vector2:
	if path.is_empty():
		build_patrol_path(spawn_pos, facing_dir)

	var target_pt := path[path_i]
	if cur_pos.distance_to(target_pt) <= patrol_reach_eps:
		path_i += 1
		if path_i >= path.size():
			build_patrol_path(spawn_pos, facing_dir)
		else:
			target_pt = path[path_i]
	return target_pt

func return_target(cur_pos: Vector2, spawn_pos: Vector2) -> Vector2:
	# sempre atualiza “modo” bloqueado/limpo com histerese
	var blocked := _blocked_to_spawn(cur_pos, spawn_pos)

	if blocked:
		return_blocked_frames += 1
		return_clear_frames = 0
	else:
		return_clear_frames += 1
		return_blocked_frames = 0

	# modo caminho
	if return_blocked_frames >= RETURN_CONFIRM_FRAMES:
		if path.is_empty() or path_i >= path.size():
			_build_return_path()

		var pt := path[path_i]
		if cur_pos.distance_to(pt) <= return_reach_eps:
			path_i = min(path_i + 1, path.size() - 1)
			pt = path[path_i]

		return pt

	# modo direto (mas ainda “desenha”)
	if return_clear_frames >= RETURN_CONFIRM_FRAMES:
		path = [spawn_pos]
		path_i = 0
		return spawn_pos

	# indeciso: mantém o que já estava fazendo
	if path.is_empty():
		path = [spawn_pos]
		path_i = 0
		return spawn_pos

	return path[path_i]

func build_patrol_path(spawn_pos: Vector2, facing_dir: Vector2) -> void:
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

	# volta pelo caminho
	for i in range(path.size() - 2, -1, -1):
		path.append(path[i])
	path.append(spawn_pos)

func _build_return_path():
	path.clear()
	path_i = 0

	var cur := enemy_owner.global_position
	for _k in range(return_points_max):
		var to_spawn := enemy_owner.spawn_pos - cur
		if to_spawn.length() <= return_reach_eps:
			break

		var pref := to_spawn.normalized()
		var next := _pick_reachable_point(cur, pref) # já usa ray_hit/nav_mask
		path.append(next)
		cur = next

	path.append(enemy_owner.spawn_pos) # sempre termina no spawn

func _pick_reachable_point(from: Vector2, preferred_dir: Vector2) -> Vector2:
	var tries := 10
	var best := from
	var best_dist := 0.0

	for i in range(tries):
		var jitter := deg_to_rad(randf_range(-70.0, 70.0))
		var dir := preferred_dir.rotated(jitter).normalized()
		var candidate := from + dir * patrol_step

		var hit := _ray_hit(from, candidate, nav_mask)
		var endp: Vector2 = candidate if hit.is_empty() else (hit["position"] - dir * 10.0)
		var d := from.distance_to(endp)

		if d > best_dist:
			best_dist = d
			best = endp

	if best_dist < 20.0:
		var dir2 := Vector2.RIGHT.rotated(randf() * TAU)
		return from + dir2 * 40.0

	return best

func _blocked_to_spawn(cur_pos: Vector2, spawn_pos: Vector2) -> bool:
	var dir := enemy_owner.motor.facing_dir
	if dir.length() < 0.01:
		dir = (spawn_pos - cur_pos)
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	var origin := cur_pos + dir.normalized() * 6.0
	var hit := _ray_hit(origin, spawn_pos, nav_mask)
	return not hit.is_empty()


func _ray_hit(from: Vector2, to: Vector2, mask_to_check: int) -> Dictionary:
	var space := enemy_owner.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = mask_to_check

	var ex: Array[RID] = []
	ex.append(enemy_owner.get_rid())

	for c in enemy_owner.get_children():
		if c is CollisionObject2D:
			ex.append(c.get_rid())

	if enemy_owner.has_node("KillZone"):
		var kz := enemy_owner.get_node("KillZone")
		if kz is CollisionObject2D:
			ex.append(kz.get_rid())

	q.exclude = ex

	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.hit_from_inside = true
	return space.intersect_ray(q)

func draw_path(canvas: Node2D, cur_pos: Vector2, state: int) -> void:
	if state not in [EnemyBrain.State.PATROL, EnemyBrain.State.RETURN] or path.is_empty():
		return

	var idx: float = clamp(path_i, 0, path.size() - 1)

	# começa no inimigo e vai só pro target atual (uma perninha)
	var prev := enemy_owner.to_local(cur_pos)
	canvas.draw_line(prev, enemy_owner.to_local(path[idx]), path_line_color, 2.0)

	# desenha o restante do caminho a partir do idx
	prev = enemy_owner.to_local(path[idx])
	for j in range(idx + 1, path.size()):
		var p := enemy_owner.to_local(path[j])
		canvas.draw_line(prev, p, path_line_color, 2.0)
		prev = p

	canvas.draw_circle(enemy_owner.to_local(path[idx]), 5.0, path_point_color)

func reset_to_spawn():
	enemy_owner.global_position = enemy_owner.spawn_pos
	enemy_owner.velocity = Vector2.ZERO
	enemy_owner.state = enemy_owner.State.PATROL
	enemy_owner.last_seen_pos = Vector2.ZERO
	build_patrol_path(enemy_owner.spawn_pos, enemy_owner.motor.facing_dir)

func clear_path() -> void:
	path.clear()
	path_i = 0

func set_direct_target(p: Vector2) -> void:
	path = [p]
	path_i = 0


func build_direction_change_arc(from_direction: float, to_direction: float, angle_points: int = enemy_owner.points_per_direction_change) -> Array[Vector2]:
	var calculated_arc: Array[Vector2] = []
	for i in range(angle_points):
		var t: float = float(i) / max(angle_points - 1, 1)
		var angle := lerp_angle(from_direction, to_direction, t)
		var dir := Vector2.RIGHT.rotated(angle)
		var point := enemy_owner.global_position + dir * 60.0
		calculated_arc.append(point)
	return calculated_arc

# Calcula um arco de investigação entre dois pontos
func build_investigate_arc() -> void:
	investigate_arc.clear()
	investigate_arc_i = 0
	var current_angle = enemy_owner.motor.facing_dir.angle()
	var angle_start: float = current_angle - deg_to_rad(arc_degrees / 2.0)
	var angle_end: float = current_angle + deg_to_rad(arc_degrees / 2.0)
	var arc_points := int(enemy_owner.investigate_time * 24)
	var rotate_points := int(arc_points * 0.25)
	var arc_only_points := arc_points - rotate_points
	investigate_arc += build_direction_change_arc(
		current_angle,
		angle_start,
		rotate_points
	)
	investigate_arc += build_direction_change_arc(
		angle_start,
		angle_end,
		arc_only_points
	)

# Avança ao longo do arco conforme o tempo de investigação
func investigate_target(progress: float) -> Vector2:
	if investigate_arc.is_empty():
		return enemy_owner.global_position
	var idx: int = clamp(int(progress * (investigate_arc.size() - 1)), 0, investigate_arc.size() - 1)
	investigate_arc_i = idx
	return investigate_arc[idx]
