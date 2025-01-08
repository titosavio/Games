extends Area2D

const BULLET = preload("res://scenes/bullet.tscn")
var time_alive = 0

func _physics_process(delta: float) -> void:
    var enemies_in_range = get_overlapping_bodies()
    if enemies_in_range.size() > 0:
        var target_enemy = enemies_in_range[0]
        look_at(target_enemy.global_position)

func shoot():
    var new_bullet = BULLET.instantiate()
    new_bullet.global_position = %Muzzle.global_position
    new_bullet.global_rotation = %Muzzle.global_rotation
    %Muzzle.add_child(new_bullet)


func _on_timer_timeout() -> void:
    time_alive += 1
    if time_alive <= GameManager.GLOBAL_BULLET_DELAY:
        return
    shoot()
