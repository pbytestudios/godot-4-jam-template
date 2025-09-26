@tool
extends Polygon2D

@export var collision_poly: CollisionPolygon2D

func _ready():
	#we do not need this script in-game
	if !Engine.is_editor_hint():
		set_script(null)

func _process(delta):
	if Engine.is_editor_hint():
		if collision_poly == null:
			printerr("Must have a collision polygon!")
		else:
			var adjusted : PackedVector2Array = PackedVector2Array(self.polygon)
			collision_poly.polygon = adjusted
			collision_poly.global_position = global_position
