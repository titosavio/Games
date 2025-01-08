extends Card

@onready var player := $"../Player"
@onready var DiceScript = preload("res://scripts/dice.gd")
@onready var dice = DiceScript.new()

var monster_hp = int(Globals.cards_openned) + dice.roll_dice(1, 6)[0]

var monsters = [
	{ "name": "Undead Soldier", "damage": 2, "xp": 1 },
	{ "name": "Skeleton", "damage": 4, "xp": 1 },
	{ "name": "Undead Knight", "damage": 6, "xp": 2 },
	{ "name": "Serpent King", "damage": 8, "xp": 2 },
	{ "name": "Og's Sanctum Guard", "damage": 10, "xp": 3 }
]

func init_monster(rank):
	var monster_data = monsters[rank]
	print("Found a %s with %s health and %s damage" % [monster_data.name, str(monster_hp), str(monster_data.damage)])
	damage = monster_data.damage
	exp_reward = monster_data.xp

func fight():
	print("Fighting")
	# TODO enter combat
	



func _ready() -> void:
	pass
