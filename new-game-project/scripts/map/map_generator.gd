extends Node
class_name BSPMapGenerator

class MapData:
	var width: int
	var height: int
	var cell_size: int
	var walkable: PackedByteArray # 0/1 por célula (width*height)
	var rooms: Array[Rect2i] = []
	var corridors: Array[Rect2i] = []
	var start_cell: Vector2i
	var exit_cell: Vector2i

	func _init(w: int, h: int, cs: int):
		width = w
		height = h
		cell_size = cs
		walkable = PackedByteArray()
		walkable.resize(width * height)
		for i in range(walkable.size()):
			walkable[i] = 0

	func idx(x: int, y: int) -> int:
		return y * width + x

	func in_bounds(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < width and y < height

	func set_walkable_rect(r: Rect2i) -> void:
		for y in range(r.position.y, r.position.y + r.size.y):
			for x in range(r.position.x, r.position.x + r.size.x):
				if in_bounds(x, y):
					walkable[idx(x, y)] = 1

	func is_walkable(x: int, y: int) -> bool:
		if not in_bounds(x, y): return false
		return walkable[idx(x, y)] == 1

	func cell_to_world(c: Vector2i) -> Vector2:
		return (Vector2(c) + Vector2(0.5, 0.5)) * float(cell_size)

class BSPNode:
	var rect: Rect2i
	var left: BSPNode
	var right: BSPNode
	var room: Rect2i = Rect2i()
	var room_center: Vector2i = Vector2i(-1, -1)

	func _init(r: Rect2i):
		rect = r

func generate(
	width_cells: int = 160,
	height_cells: int = 120,
	cell_size: int = 32,
	_seed: int = 0,
	min_leaf: int = 14,
	max_depth: int = 5,
	room_margin: int = 2,
	room_min_size: Vector2i = Vector2i(6, 6),
) -> MapData:
	if _seed != 0:
		seed(_seed)
	else:
		randomize()

	var data := MapData.new(width_cells, height_cells, cell_size)
	var root := BSPNode.new(Rect2i(Vector2i(0, 0), Vector2i(width_cells, height_cells)))

	var leaves: Array[BSPNode] = []
	_split_bsp(root, 0, max_depth, min_leaf, leaves)

	# cria salas em cada leaf
	for leaf in leaves:
		leaf.room = _make_room_in_leaf(leaf.rect, room_margin, room_min_size)
		leaf.room_center = Vector2i(
			int(leaf.room.position.x + leaf.room.size.x / 2.0),
			int(leaf.room.position.y + leaf.room.size.y / 2.0)
		)
		data.rooms.append(leaf.room)
		data.set_walkable_rect(leaf.room)

	# conecta recursivamente (corredores)
	_connect_children(root, data)

	# start/exit: pega duas salas distantes
	if data.rooms.size() > 0:
		data.start_cell = _pick_room_center(data.rooms[0])
		data.exit_cell = data.start_cell
		var best_d := -1.0
		for r in data.rooms:
			var c := _pick_room_center(r)
			var d := c.distance_to(data.start_cell)
			if d > best_d:
				best_d = d
				data.exit_cell = c

	return data

func _split_bsp(node: BSPNode, depth: int, max_depth: int, min_leaf: int, out_leaves: Array[BSPNode]) -> void:
	if depth >= max_depth:
		out_leaves.append(node)
		return

	var r := node.rect
	var can_split_h := r.size.y >= min_leaf * 2
	var can_split_v := r.size.x >= min_leaf * 2
	if not can_split_h and not can_split_v:
		out_leaves.append(node)
		return

	var split_h := false
	if can_split_h and can_split_v:
		# tende a dividir no eixo mais longo
		split_h = r.size.y > r.size.x
	elif can_split_h:
		split_h = true
	else:
		split_h = false

	if split_h:
		var split := r.position.y + randi_range(min_leaf, r.size.y - min_leaf)
		var top := Rect2i(r.position, Vector2i(r.size.x, split - r.position.y))
		var bot := Rect2i(Vector2i(r.position.x, split), Vector2i(r.size.x, r.position.y + r.size.y - split))
		node.left = BSPNode.new(top)
		node.right = BSPNode.new(bot)
	else:
		var split := r.position.x + randi_range(min_leaf, r.size.x - min_leaf)
		var left := Rect2i(r.position, Vector2i(split - r.position.x, r.size.y))
		var right := Rect2i(Vector2i(split, r.position.y), Vector2i(r.position.x + r.size.x - split, r.size.y))
		node.left = BSPNode.new(left)
		node.right = BSPNode.new(right)

	_split_bsp(node.left, depth + 1, max_depth, min_leaf, out_leaves)
	_split_bsp(node.right, depth + 1, max_depth, min_leaf, out_leaves)

func _make_room_in_leaf(leaf: Rect2i, margin: int, room_min: Vector2i) -> Rect2i:
	var max_w: int = max(leaf.size.x - margin * 2, room_min.x)
	var max_h: int = max(leaf.size.y - margin * 2, room_min.y)

	var w := randi_range(room_min.x, max_w)
	var h := randi_range(room_min.y, max_h)

	var x := randi_range(leaf.position.x + margin, leaf.position.x + leaf.size.x - margin - w)
	var y := randi_range(leaf.position.y + margin, leaf.position.y + leaf.size.y - margin - h)
	return Rect2i(Vector2i(x, y), Vector2i(w, h))

func _connect_children(node: BSPNode, data: MapData) -> void:
	if node.left == null or node.right == null:
		return

	_connect_children(node.left, data)
	_connect_children(node.right, data)

	# conecta centro de sala mais próxima em cada subárvore
	var a := _find_room_center(node.left)
	var b := _find_room_center(node.right)
	if a.x < 0 or b.x < 0:
		return

	# corredor em L
	if randf() < 0.5:
		_carve_corridor(data, a, Vector2i(b.x, a.y))
		_carve_corridor(data, Vector2i(b.x, a.y), b)
	else:
		_carve_corridor(data, a, Vector2i(a.x, b.y))
		_carve_corridor(data, Vector2i(a.x, b.y), b)

func _carve_corridor(data: MapData, from: Vector2i, to: Vector2i) -> void:
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y

	if x0 == x1:
		var y_min: int = min(y0, y1)
		var y_max: int = max(y0, y1)
		var r := Rect2i(Vector2i(x0, y_min), Vector2i(1, y_max - y_min + 1))
		data.corridors.append(r)
		data.set_walkable_rect(r)
	elif y0 == y1:
		var x_min: int = min(x0, x1)
		var x_max: int = max(x0, x1)
		var r := Rect2i(Vector2i(x_min, y0), Vector2i(x_max - x_min + 1, 1))
		data.corridors.append(r)
		data.set_walkable_rect(r)

func _find_room_center(node: BSPNode) -> Vector2i:
	if node == null:
		return Vector2i(-1, -1)
	if node.room_center.x >= 0:
		return node.room_center
	var a := _find_room_center(node.left)
	if a.x >= 0:
		return a
	return _find_room_center(node.right)

func _pick_room_center(r: Rect2i) -> Vector2i:
	return Vector2i(r.position.x + int(r.size.x / 2.0), r.position.y + int(r.size.y / 2.0))
