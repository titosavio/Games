extends Node2D

func _ready():
    for e in $Enemies.get_children():
        if e is Enemy:
            e.setup(Game.adversaries)
