extends Node2D
class_name EnemySpawner

@export var enemies_per_room_min: int = 1
@export var enemies_per_room_max: int = 3
@export var rooms_to_populate_min: int = 3
@export var rooms_to_populate_max: int = 6
@export var min_dist_from_player_px: float = 220.0
@export var safe_padding_cells: int = 1

func spawn_enemies(data, world_parent: Node, player: Node2D, adversary_system: AdversarySystem, enemy_scene: PackedScene) -> Array:
	if enemy_scene == null:
		push_error("SpawnDirector: enemy_scene não setada.")
		return []

	var start_room_idx := _find_room_index_containing_cell(data.rooms, data.start_cell)
	var candidate_rooms: Array[int] = []
	for i in range(data.rooms.size()):
		if i == start_room_idx:
			continue
		candidate_rooms.append(i)

	candidate_rooms.shuffle()

	var rooms_to_populate: int = clamp(randi_range(rooms_to_populate_min, rooms_to_populate_max), 0, candidate_rooms.size())
	var spawned: Array = []

	for k in range(rooms_to_populate):
		var room: Rect2i = data.rooms[candidate_rooms[k]]
		var enemies_in_room := randi_range(enemies_per_room_min, enemies_per_room_max)

		for _e in range(enemies_in_room):
			var cell := _pick_safe_cell_in_room(data, room, safe_padding_cells)
			if cell.x < 0:
				continue

			var pos: Vector2 = data.cell_to_world(cell)
			if player != null and pos.distance_to(player.global_position) < min_dist_from_player_px:
				continue

			var enemy := enemy_scene.instantiate()
			world_parent.add_child(enemy)
			enemy.set_spawn_position(pos)
			enemy.global_position = pos

			# integra com teu sistema existente
			if adversary_system != null and player != null and enemy.has_method("setup"):
				enemy.setup(adversary_system, player)

			spawned.append(enemy)

	return spawned

func _find_room_index_containing_cell(rooms: Array, cell: Vector2i) -> int:
	for i in range(rooms.size()):
		var r: Rect2i = rooms[i]
		if cell.x >= r.position.x and cell.y >= r.position.y and cell.x < r.position.x + r.size.x and cell.y < r.position.y + r.size.y:
			return i
	return -1

func _pick_safe_cell_in_room(data, room: Rect2i, pad: int) -> Vector2i:
	var tries := 200
	for _i in range(tries):
		var x := randi_range(room.position.x + pad, room.position.x + room.size.x - 1 - pad)
		var y := randi_range(room.position.y + pad, room.position.y + room.size.y - 1 - pad)
		if not data.is_walkable(x, y):
			continue

		# evita colar em parede (4-vizinhos)
		if not data.is_walkable(x + 1, y): continue
		if not data.is_walkable(x - 1, y): continue
		if not data.is_walkable(x, y + 1): continue
		if not data.is_walkable(x, y - 1): continue

		return Vector2i(x, y)

	return Vector2i(-1, -1)
