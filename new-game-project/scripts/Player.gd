extends CharacterBody2D
class_name Player

@export var speed := 250.0
@export var respawn_pos := Vector2(120, 120)

signal died(respawn_pos: Vector2)

func _physics_process(_delta):
	var dir = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = dir * speed
	move_and_slide()

func die(killer: Enemy):
	killer.on_player_killed("encostou em mim (fatal)")
	global_position = respawn_pos
	velocity = Vector2.ZERO

	emit_signal("died", respawn_pos)
