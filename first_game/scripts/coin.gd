extends Area2D

var inventory_item_name = "coins"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.get("is_main_char") and "inventory" in body:
		if inventory_item_name not in body.get("inventory"):
			body.inventory[inventory_item_name] = 0
		body.inventory[inventory_item_name] += 1
		body.skills["has_inf_jumps"] = add_inf_jumps(body.inventory[inventory_item_name])
		
		print(body.inventory[inventory_item_name])
		queue_free() # deletes the scene!!

func add_inf_jumps(total_coins: int) -> bool:
	if total_coins >= 5:
		return true
	return false
