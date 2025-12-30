class_name AdversarySystem
extends RefCounted

var adversaries: Dictionary = {}
var last_killer_id := ""

func get_or_create(enemy_id: String) -> AdversaryProfile:
	if not adversaries.has(enemy_id):
		adversaries[enemy_id] = AdversaryProfile.new(enemy_id)
	return adversaries[enemy_id]

func register_kill(enemy_id: String, context: String) -> AdversaryProfile:
	var a := get_or_create(enemy_id)
	last_killer_id = enemy_id

	a.kills += 1
	a.rank += 1

	if a.name == "":
		a.name = _generate_name()

	a.traits.append(_pick_trait())

	a.memories.append(context)

	var trait_str := a.traits[-1] if a.traits.size() > 0 else ""
	a.full_name = "%s (rank %d) %s" % [a.name, a.rank, trait_str]
	return a

func get_last_adversary() -> AdversaryProfile:
	if last_killer_id == "":
		return null
	return adversaries[last_killer_id]


func _generate_name() -> String:
	var a = ["Eco", "Garra", "Sombra", "Faca", "Dente", "Olho"]
	var b = ["Frio", "Cruel", "Veloz", "Torto", "Silencioso", "Vingativo"]
	return "%s %s" % [a[randi() % a.size()], b[randi() % b.size()]]

func _pick_trait() -> String:
	var traits = ["Vingativo", "Cruel", "Covarde", "Orgulhoso", "Faminto"]
	return traits[randi() % traits.size()]

func is_empty() -> bool:
	return adversaries.is_empty()