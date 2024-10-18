class_name Card

extends Node

var damage: int = 0:
	set(dmg):
		damage = clamp(dmg, 0, 1000)
		print('Damage delt: ', str(damage))
	
signal earned_xp(exp_reward)

var exp_reward: int = 0:
	set(exp):
		exp_reward = clamp(exp, 0, 1000)
		earned_xp.emit(exp_reward)
		print('Earned %s poins of experience' % exp_reward)
	
func _ready():
	exp_reward = 10
