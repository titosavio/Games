extends Node2D
class_name MapBuilder

@export var wall_thickness_px: float = 32.0 # igual ao cell_size normalmente
@export var build_debug_floor: bool = true
@export var build_walls: bool = true
@export var build_navigation: bool = true

var _data: BSPMapGenerator.MapData
var _wall_parent: Node2D
var _nav_parent: Node2D

func rebuild(data: BSPMapGenerator.MapData) -> void:
	_data = data

	# limpa filhos antigos
	for c in get_children():
		c.queue_free()

	_wall_parent = Node2D.new()
	_wall_parent.name = "Walls"
	add_child(_wall_parent)

	_nav_parent = Node2D.new()
	_nav_parent.name = "Navigation"
	add_child(_nav_parent)

	if build_walls:
		_build_walls_from_grid()
	if build_navigation:
		_build_nav_regions_rects()

	queue_redraw()

func _draw() -> void:
	if _data == null or not build_debug_floor:
		return

	var cs := float(_data.cell_size)

	# desenha walkable como retângulos (debug)
	for y in range(_data.height):
		for x in range(_data.width):
			if _data.is_walkable(x, y):
				draw_rect(Rect2(Vector2(x, y) * cs, Vector2(cs, cs)), Color(0.15, 0.15, 0.2, 1.0), true)

	# marca start/exit
	draw_circle(_data.cell_to_world(_data.start_cell), cs * 0.35, Color(0.2, 1.0, 0.2, 0.9))
	draw_circle(_data.cell_to_world(_data.exit_cell), cs * 0.35, Color(1.0, 0.2, 0.2, 0.9))

func _build_walls_from_grid() -> void:
	var cs := float(_data.cell_size)

	# cria parede como “bloco” (cell) onde é sólido e encosta em walkable
	for y in range(_data.height):
		for x in range(_data.width):
			if _data.is_walkable(x, y):
				continue

			var touches := false
			if _data.is_walkable(x + 1, y): touches = true
			elif _data.is_walkable(x - 1, y): touches = true
			elif _data.is_walkable(x, y + 1): touches = true
			elif _data.is_walkable(x, y - 1): touches = true

			if not touches:
				continue

			var body := StaticBody2D.new()
			body.position = (Vector2(x, y) + Vector2(0.5, 0.5)) * cs
			body.collision_layer = 1 << 1 # layer 2 (ajusta conforme seu projeto)
			body.collision_mask = 0

			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(cs, cs)
			shape.shape = rect

			body.add_child(shape)
			_wall_parent.add_child(body)

func _build_nav_regions_rects() -> void:
	# navmesh retangular por sala e corredor (simples, ótimo pro MVP)
	for r in _data.rooms:
		_add_nav_region_for_rect(r)
	for c in _data.corridors:
		_add_nav_region_for_rect(c)

func _add_nav_region_for_rect(r: Rect2i) -> void:
	var cs := float(_data.cell_size)

	var region := NavigationRegion2D.new()
	var poly := NavigationPolygon.new()

	region.position = Vector2(r.position) * cs

	var w := float(r.size.x) * cs
	var h := float(r.size.y) * cs

	# Define um polígono retangular diretamente (sem outlines/bake)
	# NavigationPolygon usa "vertices" + "polygons" (índices)
	poly.vertices = PackedVector2Array([
		Vector2(0, 0),
		Vector2(w, 0),
		Vector2(w, h),
		Vector2(0, h),
	])
	poly.polygons = [PackedInt32Array([0, 1, 2, 3])]

	region.navigation_polygon = poly
	_nav_parent.add_child(region)

