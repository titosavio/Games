extends Control

var armor: int = 0:
	set(val):
		armor = clamp(val, 0, 5)
		print("Current armor: ", str(armor))
	
var hp: int = 1:
	set(val):
		hp = clamp(val, 0, 20)
		print("Current HP: ", str(hp))
		
var gold: int = 0:
	set(val):
		gold = clamp(val, 0, 20)
		print("Current gold: ", str(gold))

var food: int = 0:
	set(val):
		food = clamp(val, -2, 6)
		if food < 0:
			print("No more food, hit for 2 HP")
			hp += 2
			

enum rank {rank_1, rank_2, rank_3, rank_4}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
