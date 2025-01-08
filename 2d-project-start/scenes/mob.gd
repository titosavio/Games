extends CharacterBody2D

var HEALTH = 100
var DPS = 10

const SMOKE_EXPLOSION = preload("res://smoke_explosion/smoke_explosion.tscn")
var touching_bodies = []

func _ready() -> void:
    %Slime.play_walk()


func _physics_process(delta: float) -> void:
    var player = GameManager.get_player()
    
    if not player:
        return 
    
    var direction = global_position.direction_to(player.global_position)
    velocity = direction * 300
    move_and_slide()
    handle_touching_bodies(delta)

func take_damage(damage: float):
    HEALTH -= damage
    %Slime.play_hurt()
    if HEALTH <= 0:
        die()
    
func die():
    print("Mob died!")
    queue_free()
    var explosion = SMOKE_EXPLOSION.instantiate()
    get_parent().add_child(explosion)
    explosion.global_position = global_position

func handle_touching_bodies(delta: float) -> void:
    for touching_body in touching_bodies:
        if touching_body and touching_body is Node and touching_body.has_method("take_damage_from_mob"):
            touching_body.take_damage_from_mob(DPS * delta)

func _on_damage_box_area_entered(area: Area2D) -> void:
    var body = area.get_parent()
    if body not in touching_bodies:
        touching_bodies.append(body)

func _on_hurt_box_area_exited(area: Area2D) -> void:
    var body = area.get_parent()
    while body in touching_bodies:
        touching_bodies.erase(body)
