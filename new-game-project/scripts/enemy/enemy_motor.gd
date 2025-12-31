extends Node
class_name EnemyMotor

var enemy_owner: CharacterBody2D

var accel := 10.0
var facing_dir := Vector2.RIGHT

var facing_dir_change_arc: Array[Vector2] = []

func setup(o: CharacterBody2D, accel_val: float) -> void:
	enemy_owner = o
	accel = accel_val

func look_towards(point: Vector2) -> void:
	var v := point - enemy_owner.global_position
	if v.length() < 0.001:
		return
	facing_dir = v.normalized()

func move_towards(point: Vector2, speed: float, delta: float) -> void:
	var v := point - enemy_owner.global_position
	var dist := v.length()

	if dist < 0.001:
		enemy_owner.velocity = enemy_owner.velocity.lerp(Vector2.ZERO, accel * delta)
		return

	var dir := v / dist
	if dir.dot(facing_dir) < 0.999:
		facing_dir_change_arc = enemy_owner.nav.build_direction_change_arc(facing_dir.angle(), dir.angle())
		for i in range(facing_dir_change_arc.size()):
			look_towards(facing_dir_change_arc[i])
			await enemy_owner.get_tree().process_frame
		facing_dir = dir

	var desired := dir * speed
	enemy_owner.velocity = enemy_owner.velocity.lerp(desired, accel * delta)
