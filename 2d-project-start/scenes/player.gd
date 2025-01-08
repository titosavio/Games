extends CharacterBody2D

var MAX_SPEED = 600
var CURRENT_SPEED = 0
var ACCELERATION = 60 * 8
var MAX_HEALTH = 100.0
var HEALTH = MAX_HEALTH

var last_dir = Vector2(0,0)
@onready var health_bar = %HealthBar

signal health_depleted

func _ready():
    GameManager.player = self
    health_bar.max_value = MAX_HEALTH
    health_bar.value = HEALTH
    
func _physics_process(delta: float) -> void:
    var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
    
    if direction.length() != 0:
        last_dir = direction
        velocity = speed_up(delta, direction)
        %HappyBoo.play_walk_animation()
    else:
        velocity = slow_down(delta, last_dir)
        %HappyBoo.play_idle_animation()
        
    move_and_slide()
    
    var overlapping_mobs = %HurtBox.get_overlapping_bodies()
        
func speed_up(delta: float, direction: Vector2) -> Vector2:
    CURRENT_SPEED += max(ACCELERATION * delta, 0)
    CURRENT_SPEED = min(MAX_SPEED, CURRENT_SPEED)
    return direction * CURRENT_SPEED

func slow_down(delta: float, direction: Vector2) -> Vector2:
    if direction.length() == 0:
        CURRENT_SPEED = 0
        return Vector2(0,0)
    CURRENT_SPEED -= max(ACCELERATION * delta * 4, 0)
    if CURRENT_SPEED <= 0:
        last_dir = Vector2(0,0)
        return Vector2(0,0)
    return direction * CURRENT_SPEED

func take_damage_from_mob(dmg: float):
    HEALTH -= dmg
    health_bar.value = HEALTH
    print("Took damage from mob!. Current health: ", str(HEALTH))
    if HEALTH <= 0:
        print("Game over baby!")
        health_depleted.emit()
