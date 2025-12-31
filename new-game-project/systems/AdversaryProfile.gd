class_name AdversaryProfile
extends RefCounted

var id: String
var name: String = ""
var rank: int = 1
var kills: int = 0
var traits: Array[String] = []
var memories: Array[String] = []
var full_name: String = ""

func _init(enemy_id: String):
	id = enemy_id

func is_empty() -> bool:
	return name == "" and kills == 0 and traits.is_empty() and memories.is_empty()

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"rank": rank,
		"kills": kills,
		"traits": traits,
		"memories": memories,
		"full_name": full_name
	}


func from_dict(d: Dictionary) -> void:
	id = str(d.get("id", id))
	name = str(d.get("name", ""))
	rank = int(d.get("rank", 1))
	kills = int(d.get("kills", 0))

	traits.clear()
	for t in d.get("traits", []):
		traits.append(str(t))

	memories.clear()
	for m in d.get("memories", []):
		memories.append(str(m))

	full_name = str(d.get("full_name", ""))
