extends CharacterBody2D


var is_main_char = true

var inventory = {}
var skills = {
	"has_inf_jumps": false
}

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

var double_jump = false
var has_jumped = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("wasd_up")):
		if not has_jumped:
			velocity.y = JUMP_VELOCITY
			double_jump = true
			has_jumped = true
		elif double_jump or skills["has_inf_jumps"]:
			velocity.y = 0 #max(0, velocity.y)
			velocity.y += JUMP_VELOCITY * 0.8
			double_jump = false
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := 0
	direction += Input.get_axis("ui_left", "ui_right")
	direction += Input.get_axis("wasd_left", "wasd_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if is_on_floor():
		double_jump = false
		has_jumped = false
