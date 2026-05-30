@tool
class_name PolygonScatter
extends Node2D

@export var polygon: Polygon2D
@export var packed_scenes: Array[PackedScene]
@export_range(0.0, 1.0) var density: float = 0.5
@export var max_instances: int = 100
@export var min_spacing: float = 50.0
@export var edge_margin: float = 0.0
@export_range(0.001, 100.0) var min_scale: float = 1.0
@export_range(0.002, 1000.0) var max_scale: float = 1.0

@export_tool_button("Bake") var call_bake = scatter
@export_tool_button("Clear") var call_clear = _clear_instances

@export_storage var _baked:bool = false

func _ready():
	if !Engine.is_editor_hint():
		if !_baked:
			scatter()
		polygon.visible = false

func scatter():
	_clear_instances()
	_baked = true
	
	if not _validate_inputs():
		return
#
	var target_count: int = int(float(max_instances) * density)
	var positions: Array[Vector2] = _generate_positions(target_count)
#
	for pos in positions:
		_instantiate_scene(pos)

func _validate_inputs() -> bool:
	if polygon == null:
		push_warning("PolygonScatter: No polygon assigned")
		return false

	if packed_scenes.size() == 0:
		push_warning("PolygonScatter: No packed scenes assigned")
		return false

	if density <= 0.0:
		return false
	return true

func _clear_instances():
	U.free_children(self)
	_baked = false

func _generate_positions(target_count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var polygon_points: PackedVector2Array = polygon.polygon
	var bounds: Rect2 = _get_bounds(polygon_points)

	var max_attempts: int = 10000
	var attempts: int = 0

	while positions.size() < target_count and attempts < max_attempts:
		attempts += 1

		var candidate: Vector2 = Vector2(
			randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)

		if not _is_point_in_polygon(candidate, polygon_points):
			continue

		if edge_margin > 0.0 and not _is_distance_from_edge_valid(candidate, polygon_points):
			continue

		if density < 1.0 and  not _is_valid_spacing(candidate, positions):
			continue

		positions.append(candidate)

	if positions.size() < target_count:
		push_warning("PolygonScatter: Could only place %d of %d instances" % [positions.size(), target_count])

	return positions


func _get_bounds(points: PackedVector2Array) -> Rect2:
	if points.size() == 0:
		return Rect2()

	var min_x: float = points[0].x
	var max_x: float = points[0].x
	var min_y: float = points[0].y
	var max_y: float = points[0].y

	for i in range(points.size()):
		var point: Vector2 = points[i]
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)

	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _is_point_in_polygon(point: Vector2, polygon_points: PackedVector2Array) -> bool:
	var inside: bool = false
	var j: int = polygon_points.size() - 1

	for i in range(polygon_points.size()):
		var xi: float = polygon_points[i].x
		var yi: float = polygon_points[i].y
		var xj: float = polygon_points[j].x
		var yj: float = polygon_points[j].y

		if ((yi > point.y) != (yj > point.y)) and (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi):
			inside = not inside

		j = i

	return inside


func _is_valid_spacing(new_pos: Vector2, positions: Array[Vector2]) -> bool:
	if min_spacing <= 0.0:
		return true

	for pos in positions:
		if new_pos.distance_to(pos) < min_spacing:
			return false

	return true


func _is_distance_from_edge_valid(point: Vector2, polygon_points: PackedVector2Array) -> bool:
	for i in range(polygon_points.size()):
		var p1: Vector2 = polygon_points[i]
		var p2: Vector2 = polygon_points[(i + 1) % polygon_points.size()]

		var dist: float = _point_to_line_distance(point, p1, p2)
		if dist < edge_margin:
			return false
	return true


func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_dir: Vector2 = line_end - line_start
	var line_len: float = line_dir.length()

	if line_len == 0.0:
		return point.distance_to(line_start)

	var t: float = clamp((point - line_start).dot(line_dir) / (line_len * line_len), 0.0, 1.0)
	var closest: Vector2 = line_start + line_dir * t

	return point.distance_to(closest)


func _instantiate_scene(position: Vector2):
	var scene: PackedScene = packed_scenes.pick_random()
	var instance: Node = scene.instantiate()

	add_child(instance)
	instance.position = position
	instance.scale = Vector2.ONE * randf_range(min_scale, max_scale)
