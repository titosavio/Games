extends Node
class_name SaveLoad

const SAVE_PATH := "user://save_v1.json"
const USE_SAVES := false

func save() -> void:
	if not USE_SAVES:
		return

	var state: Dictionary = {
		"version": 1,
		"adversaries": Game.adversaries.to_dict(),
		"world_state": Game.world_state,
		"player": Game.player.to_dict(),
	}

	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Failed to open save file for writing: %s" % SAVE_PATH)
		return

	f.store_string(JSON.stringify(state))
	f.close()

	print("Game saved to %s" % SAVE_PATH)

func load() -> Dictionary:
	if not USE_SAVES:
		return {}
		
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_error("Failed to open save file for reading: %s" % SAVE_PATH)
		return {}

	var text := f.get_as_text()
	f.close()

	var parser := JSON.new()
	var err := parser.parse(text)
	if err != OK:
		push_error("Save JSON parse error: %s at line %d" % [parser.get_error_message(), parser.get_error_line()])
		return {}

	var state: Variant = parser.data
	if typeof(state) != TYPE_DICTIONARY:
		push_error("Save file root is not a Dictionary")
		return {}

	# aplica no Game aqui ou devolve pra quem chamou
	if state.has("adversaries"):
		Game.adversaries.from_dict(state["adversaries"])
	if state.has("world_state"):
		Game.world_state = state["world_state"]
	if state.has("player"):
		Game.call_deferred("_apply_player_save", state["player"])

	return state
