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