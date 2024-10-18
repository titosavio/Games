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
			
var xp: int = 0

enum rank {rank_1, rank_2, rank_3, rank_4}
var player_rank = rank.rank_1

var spells := {
	"fire": 0,
	"ice": 0,
	"poison": 0,
	"heal": 0
}

func add_xp(val: int) -> void:
	xp += val
	print("XP added: ", xp)
	if xp >= (int(player_rank) + 1) * 6:
		increase_rank()

func increase_rank() -> void:
	if player_rank < rank.rank_4:
		player_rank += 1
		print("Rank up! New rank: ", player_rank)
	else:
		print("Max rank reached.")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_earned_xp(val: int) -> void:
	add_xp(val)
		
