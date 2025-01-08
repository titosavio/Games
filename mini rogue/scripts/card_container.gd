class_name Card

extends Node

signal card_cleared()

var damage: int = 0:
	set(dmg):
		damage = clamp(dmg, 0, 1000)
		print('Damage delt: ', str(damage))
	
signal earned_xp(exp_reward: int)

var exp_reward: int = 0:
	set(exp):
		exp_reward = clamp(exp, 0, 1000)
		earned_xp.emit(exp_reward)
		print('Earned %s poins of experience' % exp_reward)

func card_solved(solved: bool = true) -> void:
	if solved:
		card_cleared.emit()
		queue_free()

func run_card() -> void:
	print('Running', str(get_tree().get_current_scene().get_name()))
	print('Card solved')
	var solved = true
	card_solved(solved)

func _ready():
	pass
