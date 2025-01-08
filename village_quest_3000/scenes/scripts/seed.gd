class_name GameSeed
extends Resource  # Changed from RefCounted to Resource for better editor integration

@export var seed_value: int = 0  # Default value of 0

func _init(p_seed: int = 0):
    if not p_seed:
        seed_value = p_seed if p_seed != 0 else randi()
        
    seed(seed_value)

func get_seed() -> int:
    return seed_value

func use_seed():
    seed(seed_value)