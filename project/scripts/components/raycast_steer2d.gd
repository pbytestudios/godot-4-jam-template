@tool
class_name RayCastSteer2D
extends Node2D

# In Godot, a rotation of 0 points to the RIGHT
# 90 degrees points down
# -90 degrees points up

enum State {None = 0, Left = -1, Right = 1}



## The physics layers detected by the whiskers
@export_flags_2d_physics var detection_mask
## If true, the whiskers will detect Area2D collisions
@export var detect_areas:bool = false
## If true, the whiskers will detect PhysicsBody2D collisions
@export var detect_bodies:bool = true

@export_category("Whisker Parameters")
## Lengthof the left whisker
@export_range(1.0, 100.0, 1.0) var l_whisker_length:float = 10.0
## Lengthof the right whisker
@export_range(1.0, 100.0, 1.0) var r_whisker_length:float = 10.0
## Lengthof the center whisker
@export_range(1.0, 100.0, 1.0) var center_whisker_length:float = 10.0
## Left/Right whisker separation (degrees)
@export_range(10, 90, 1) var whisker_separation_degrees = 45.0
## A higher number creates a faster changing value
#@export_range(0.25, 20.0, 0.25) var steering_smoothing = 1.0
#@export var favored_steering_dir:State = State.Left
## A CollisionObject2D that will be ignored by the RayCast2Ds
@export var ignored_by_whiskers:CollisionObject2D	


## USe these to get the direction and "throttle" based on the whiskers
# 1.0 is full throttle. 0.0 is full stop
var throttle:float:
	get(): return throttle

# signals when a right or left turn should be initiated with a number from -1.0 to 1.0
# if 0.0, then no turn needed, -1 is a full left turn and 1.0 is a full right turn
var steer:float:
	get(): return steer

var l_whisker:RayCast2D = RayCast2D.new()
var c_whisker:RayCast2D = RayCast2D.new()
var r_whisker:RayCast2D = RayCast2D.new()

var state:State = State.None

func _ready():
	_create_whiskers()
	_update_whiskers()
	
	# don't enable the physics process if were running in the editor
	set_physics_process(!Engine.is_editor_hint())

func _create_whiskers():
	
	if get_child_count() == 3:
		return
	
	l_whisker.name = "LeftWhisker"
	c_whisker.name = "CenterWhisker"
	r_whisker.name = "RightWhisker"
	
	l_whisker.collision_mask = detection_mask
	c_whisker.collision_mask = detection_mask
	r_whisker.collision_mask = detection_mask
	
	l_whisker.collide_with_areas = detect_areas
	c_whisker.collide_with_areas = detect_areas
	r_whisker.collide_with_areas = detect_areas
	
	l_whisker.collide_with_bodies = detect_bodies
	r_whisker.collide_with_bodies = detect_bodies
	c_whisker.collide_with_bodies = detect_bodies
	
	if ignored_by_whiskers:
		l_whisker.add_exception(ignored_by_whiskers)
		c_whisker.add_exception(ignored_by_whiskers)
		r_whisker.add_exception(ignored_by_whiskers)
	
	add_child(l_whisker)
	add_child(c_whisker)
	add_child(r_whisker)
	
func enable_whiskers(enable:bool):
	l_whisker.enabled = enable
	c_whisker.enabled = enable
	r_whisker.enabled = enable

func reset():
	state = State.None
	throttle = 0.0
	steer = 0.0

func _update_whiskers():
	l_whisker.target_position = Vector2.RIGHT.rotated(deg_to_rad(-whisker_separation_degrees)) * l_whisker_length
	c_whisker.target_position = Vector2.RIGHT * center_whisker_length
	r_whisker.target_position = Vector2.RIGHT.rotated(deg_to_rad(whisker_separation_degrees)) * r_whisker_length

func rotate_dir() -> float:
	_update_whiskers()
	if !l_whisker.is_colliding() && !r_whisker.is_colliding():
		state = State.None
		return 0.0

	var l_dist_norm = 1.0
	var r_dist_norm = 1.0
	
	if l_whisker.is_colliding():
		l_dist_norm = l_whisker.get_collision_point().distance_squared_to(global_position) / (l_whisker_length * l_whisker_length)
		#l_dist_norm = snappedf(l_dist_norm, 0.0001)
	elif state == State.Right:
		state = State.None
		
	if r_whisker.is_colliding():
		r_dist_norm = r_whisker.get_collision_point().distance_squared_to(global_position) / (r_whisker_length * r_whisker_length)
	elif state == State.Left:
		state = State.None
		#r_dist_norm = snappedf(r_dist_norm, 0.0001)

	# collision with left whisker
	if state == State.Right || (state == State.None && l_dist_norm < r_dist_norm):
		state = State.Right
		return  (1.0 - l_dist_norm)
	# collision with right whisker 
	elif state == State.Left || (state == State.None && r_dist_norm < l_dist_norm):
		state = State.Left
		return -(1.0 - r_dist_norm)
	else: 
		return 0.0

func _process(delta: float) -> void:
	if OS.is_debug_build():
		queue_redraw()
	_update_whiskers()

func _physics_process(delta: float) -> void:
	steer = rotate_dir()
	if c_whisker.is_colliding():
		throttle = c_whisker.get_collision_point().distance_squared_to(global_position) / (center_whisker_length * center_whisker_length)
	else:
		throttle = 1.0

func _draw() -> void:
	draw_whisker(l_whisker)
	draw_whisker(c_whisker)
	draw_whisker(r_whisker)

func draw_whisker(ray:RayCast2D):
	draw_dashed_line(Vector2.ZERO, ray.target_position, Color.RED if ray.is_colliding() else Color.YELLOW)
