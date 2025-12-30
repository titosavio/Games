extends Area2D

@onready var enemy := owner as Enemy

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is Player:
		body.die(enemy)
