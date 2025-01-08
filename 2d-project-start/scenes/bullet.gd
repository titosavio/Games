extends Area2D

var SPEED = 1000
var RANGE = 1500
var DAMAGE = 25

var travelled_distance = 0

func _physics_process(delta: float) -> void:
    var direction = Vector2.RIGHT.rotated(rotation)
    position += direction * SPEED * delta
    travelled_distance += SPEED * delta
    
    if travelled_distance > RANGE:
        queue_free() # destroys the scene


func _on_body_entered(body: Node2D) -> void:
    queue_free()
    if body.has_method("take_damage"):
        body.take_damage(DAMAGE)
