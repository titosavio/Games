extends Node
class_name EnemyMotor

var enemy_owner: CharacterBody2D

var accel := 10.0
var facing_dir := Vector2.RIGHT

func setup(o: CharacterBody2D, accel_val: float) -> void:
	enemy_owner = o
	accel = accel_val

func move_towards(point: Vector2, speed: float, delta: float) -> void:
	var v := point - enemy_owner.global_position
	var dist := v.length()

	if dist < 0.001:
		enemy_owner.velocity = enemy_owner.velocity.lerp(Vector2.ZERO, accel * delta)
		return

	var dir := v / dist

	# 👉 anti-flicker: só atualiza facing se movimento for relevante e nao estive em cima
	if dir.dot(facing_dir) < 0.98 and enemy_owner.global_position.distance_to(point) > enemy_owner.shape_radius + 5.0:
		facing_dir = dir


	var desired := facing_dir * speed
	enemy_owner.velocity = enemy_owner.velocity.lerp(desired, accel * delta)
