extends Node2D

var resource_amount: int = 100

@export var resource_color: Color = Color(1, 1, 1)

func _ready() -> void:
    # Set the color of the resource node
    self.modulate = resource_color

func gather_resource(amount: int) -> int:
    var gathered = min(amount, resource_amount)
    resource_amount -= gathered
    if resource_amount <= 0:
        queue_free()
    return gathered