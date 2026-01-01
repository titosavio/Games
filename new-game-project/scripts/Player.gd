extends CharacterBody2D
class_name Player

@export var speed := 250.0
@export var respawn_pos := Vector2(120, 120)
@export var level := 1

signal died(respawn_pos: Vector2)

func _ready() -> void:
	Game.register_player(self)

func to_dict() -> Dictionary:
	return {
		"pos": [global_position.x, global_position.y],
		"speed": speed,
		"level": level,
	}

func from_dict(d: Dictionary) -> void:
	var p = d.get("pos", null)
	if p != null and p.size() == 2:
		global_position = Vector2(float(p[0]), float(p[1]))
	speed = float(d.get("speed", speed))
	level = int(d.get("level", level))

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

func set_spawn_position(pos: Vector2) -> void:
	respawn_pos = pos