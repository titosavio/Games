extends Node
class_name EnemyVision

var enemy_owner: Enemy

var view_cone_edge_color: Color = Color(1, 1, 0, 0.9)
var view_cone_fill_color: Color = Color(1, 1, 0, 0.2)

const num_cone_segments := 24

func setup(o: Enemy) -> void:
	enemy_owner = o

func can_see_target() -> bool:
	if enemy_owner.target == null: return false
	var to_target := enemy_owner.target.global_position - enemy_owner.global_position
	var dist := to_target.length()
	if dist > enemy_owner.follow_radius: return false
	if dist < 0.001: return true

	var dir := to_target / dist
	var half_angle := deg_to_rad(enemy_owner.follow_angle) / 2.0
	var dot := enemy_owner.motor.facing_dir.normalized().dot(dir)
	var ang := acos(clamp(dot, -1.0, 1.0))
	if ang > half_angle: return false

	return has_line_of_sight(enemy_owner.target.global_position)

func has_line_of_sight(to: Vector2) -> bool:
	var space := enemy_owner.get_world_2d().direct_space_state
	var q := get_view_mask(enemy_owner.global_position, to)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	return hit["collider"] == enemy_owner.target


func get_view_mask(origin, world_point: Vector2) -> PhysicsRayQueryParameters2D:
	var q := PhysicsRayQueryParameters2D.create(origin, world_point)
	q.collision_mask = enemy_owner.sight_mask
	q.exclude = [enemy_owner.get_rid()]  # <- RID!
	if enemy_owner.has_node("KillZone"):
		q.exclude.append(enemy_owner.get_node("KillZone").get_rid())
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.hit_from_inside = true
	return q

func draw_cone() -> void:
	if not enemy_owner.cone_is_visible:
		return

	var half := deg_to_rad(enemy_owner.follow_angle) * 0.5
	var forward: Vector2 = enemy_owner.motor.facing_dir.normalized()
	if forward.length() < 0.001:
		forward = Vector2.RIGHT

	var start_angle := atan2(forward.y, forward.x) - half
	var end_angle := atan2(forward.y, forward.x) + half

	var points := PackedVector2Array()
	points.append(Vector2.ZERO)

	var space: PhysicsDirectSpaceState2D = enemy_owner.get_world_2d().direct_space_state

	for i in range(num_cone_segments + 1):
		var t := float(i) / float(num_cone_segments)
		var a: float = lerp(start_angle, end_angle, t)
		var dir := Vector2(cos(a), sin(a)).normalized()

		var from: Vector2 = enemy_owner.global_position
		var to: Vector2 = enemy_owner.global_position + dir * enemy_owner.follow_radius

		var q := get_view_mask(from, to)

		var hit := space.intersect_ray(q)

		var end_world := to
		if not hit.is_empty():
			end_world = hit["position"]

		points.append(enemy_owner.to_local(end_world))

	enemy_owner.draw_colored_polygon(points, view_cone_fill_color)
	for j in range(points.size() - 1):
		enemy_owner.draw_line(points[j], points[j + 1], view_cone_edge_color, 2.0)
	enemy_owner.draw_line(points[-1], Vector2.ZERO, view_cone_edge_color, 2.0)
