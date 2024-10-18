class_name Dice

extends Node

func roll_dice(amount: int = 1, sides: int = 6) -> Array:
	if amount < 1:
		return [0]
	
	var results = []
	for roll in range(int(amount)):
		results.append(randi_range(1, int(sides)))  # Gere o valor do dado
	
	print("Rolled %s dice with the values: " % str(amount), results)
	return results

func roll_mutiple_dice(dice_dict: Dictionary) -> Dictionary:
	var return_values = {}
	for dice in dice_dict:
		return_values[dice] = roll_dice(dice_dict[dice], dice)
	return return_values
