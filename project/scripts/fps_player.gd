@tool
class_name FPSPlayer
extends CharacterBody3D

enum ControlMode {Controllable, DisableLocked, DisableVisible, Disable}
## These are required actions for this script to function
const REQUIRED_ACTIONS := ["left", "right","up", "down", "crouch", "sprint", "jump", "interact", "freelook"]

class HeadBob:
	var degrees_per_second : float
	var intensity :float
	var bob_vector:Vector3 = Vector3.ZERO:
		get: return bob_vector
		
	var _accumulated_degrees:float
	
	func _init(deg_per:float, _intensity:float):
		degrees_per_second = deg_per
		intensity = _intensity
	
	func reset(): 
		_accumulated_degrees = 0
		bob_vector = Vector3.ZERO
		
	func update(delta:float):
		_accumulated_degrees += degrees_per_second * delta
		bob_vector.y = sin(_accumulated_degrees) / 2 * intensity
		bob_vector.x = cos(_accumulated_degrees / 2) * intensity

const crouch_lerp_speed := 10.0
var bob_crouch := HeadBob.new(10.0, 0.05)
var bob_walk := HeadBob.new(14.0, 0.1)
var bob_sprint := HeadBob.new(22.0, 0.2)

const freelook_snapback_acceleration:float = 20.0
const freelook_tilt := 5.0

@export_category("Parameters")
## Mouse sensitivity
@export_range(0.05, 1, 0.001) var mouse_sensitivity = 0.25
@export_group("Head")
@export var head_bob:bool = true
# head heigh above ground (in meters)
@export_range(0.0, 2.0, 0.1) var head_height:float = 1.7:
	get: return head_height
	set(val):
		head_height = val
		if is_instance_valid(head):
			head.position.y = head_height
## head look down limit (degrees)
@export_range(-90, 0) var  min_head_rot := -60.0
## head look up limit (degrees)
@export_range(0, 90) var  max_head_rot := 85.0

@export_category("Movement")
@export_group("Capabilities")
## Freelook is useful if the player has a weapon and they need to look around wthout changing their aim
@export var can_freelook:bool = true:
	get: return can_freelook
	set(val):
		if can_freelook && !val && neck:
			neck.rotation.y = 0.0
			eyes.rotation.z = 0.0
		can_freelook = val
@export var can_sprint:bool = true
@export var can_jump:bool = true

@export_group("Speed and Acceleration")
## A value of 0 gives no control when in-air. A higher value gives more control
@export_range(0.0, 10.0) var air_acceleration = 3.0
## How fast the character accelerates when on the floor
@export var acceleration := 10.0
@export var sprint_speed:= 8.0
@export var normal_speed := 5.0
@export var crouch_speed:= 2.0
@export var jump_velocity = 4.5


@export_category("Parts")
@export var crouch_collider:CollisionShape3D
# @export_storage does not save these nodes' owner (which is this node) so they are restored
# as orphaned nodes, so we have to do it like this to preserve the owner and other properties
@export var collider:CollisionShape3D
@export var camera:Camera3D
@export var neck:Node3D
@export var head:Node3D
@export var eyes:Node3D
@export var head_ray:RayCast3D
	
var control_mode:ControlMode = ControlMode.Disable:
	get:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			control_mode = ControlMode.DisableVisible
		return control_mode
	set(val):
		match val:
			ControlMode.Controllable, ControlMode.DisableLocked:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				#enable_reticle(true)
			ControlMode.DisableVisible:
				#enable_reticle(false)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		control_mode = val
		
var gravity:float

var dead:bool

var bob_vector := Vector2.ZERO
var bob_index := 0.0 
var bob_intensity := 0.0

## Current speed of the player
var current_speed:float
## Current direction the player is traveling in
var current_dir:Vector3
var current_bob:HeadBob:
	get: return current_bob
	set(val):
		if current_bob != val:
			val.reset()
		current_bob = val

## True if we are running the game from the Editor
var _in_editor:bool

func _ready():
	_in_editor = OS.has_feature("editor")
	
	## Do not process when running in editor as a tool
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process(false)
		_add_actions()
	if _in_editor && !Engine.is_editor_hint():
		control_mode = ControlMode.Controllable

	current_bob = bob_walk
	# get gravity from project settings
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _validate_property(property: Dictionary) -> void:
	if property.name in ["collider", "camera", "neck", "eyes", "head_ray", "head"]:
		# Removes the property from the inspector, but it still saves to the .tscn
		property.usage &= ~PROPERTY_USAGE_EDITOR
		
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if can_freelook && !Input.is_action_pressed("freelook"):
		neck.rotation.y = lerp(neck.rotation.y, 0.0, freelook_snapback_acceleration * delta)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, freelook_snapback_acceleration * delta)

	if !dead && control_mode == ControlMode.Controllable:
		_do_player_control(delta)
	else:
		_lerp_dir_to(Vector3.ZERO, acceleration * delta)
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if dead: return
	
	if _in_editor:
		if control_mode != ControlMode.Controllable:
			if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed() && !event.is_echo():
				control_mode = ControlMode.Controllable
				get_viewport().set_input_as_handled()
				return
		elif control_mode == ControlMode.Controllable && event is InputEventKey && event.keycode == KEY_ESCAPE:
			control_mode = ControlMode.DisableVisible
			get_viewport().set_input_as_handled()
			return
	
	if control_mode != ControlMode.Controllable: return
	
	if event is InputEventMouseMotion:
		var mm:InputEventMouseMotion = event
		if can_freelook && Input.is_action_pressed("freelook"):
			neck.rotate_y(deg_to_rad(-event.relative.x) * mouse_sensitivity)
			neck.rotation.y = clamp(neck.rotation.y, -PI / 2, PI / 2)
			eyes.rotation.z = deg_to_rad(neck.rotation.y * freelook_tilt)
		else:
			rotate_y(deg_to_rad(-mm.relative.x * mouse_sensitivity))
			head.rotate_x(deg_to_rad(-mm.relative.y * mouse_sensitivity))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(min_head_rot), deg_to_rad(max_head_rot))
			
		get_viewport().set_input_as_handled()
	#elif current_interactable && Input.is_action_just_pressed("interact") && current_interactable.can_interact() :
			#current_interactable.interact()
			### this allows the interactable to update its description after it has been interacted with
			#current_interactable.set_interactable_ui(context.update_context)
			#get_viewport().set_input_as_handled()

func _do_player_control(delta:float):
	# Get the input direction and other controls
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var new_direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var crouching := is_instance_valid(crouch_collider) && Input.is_action_pressed("crouch")
	var sprinting := can_sprint && Input.is_action_pressed("sprint")
	
	#handle speed changes
	if crouching || _something_above_head():
		_lerp_speed_to(crouch_speed, delta)
		crouch_collider.disabled = false
		collider.disabled = true
		current_bob = bob_crouch
		head.position.y = lerp(head.position.y, _get_crouch_height(), crouch_lerp_speed * delta)
		## TODO: More here
	else:
		if sprinting:
			current_bob = bob_sprint
			_lerp_speed_to(sprint_speed, delta)
		else:
			current_bob = bob_walk
			_lerp_speed_to(normal_speed, delta)
			
		if crouch_collider:
			crouch_collider.disabled = true
			collider.disabled = false
			head.position.y = lerp(head.position.y, head_height, crouch_lerp_speed * delta)
			
	if can_jump && Input.is_action_just_pressed("jump") && is_on_floor():
		if crouching:
			velocity.y = jump_velocity / 2.0
		else:
			velocity.y = jump_velocity
			
	
	##lerp the direction change for a better 'feel'
	if is_on_floor():
		_lerp_dir_to(new_direction, acceleration * delta)
	else:
		if new_direction != Vector3.ZERO:
			_lerp_dir_to(new_direction, air_acceleration * delta)
		else:
			_lerp_dir_to(new_direction, air_acceleration / 2.0 * delta)

	if current_dir:
		velocity.x = current_dir.x * current_speed
		velocity.z = current_dir.z * current_speed
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta) 
		current_bob.reset()
	
	if !new_direction.is_equal_approx(Vector3.ZERO):
		_bob_head(delta)
		
		
func _lerp_speed_to(new_speed:float, delta:float)-> void: current_speed = lerp(current_speed, new_speed, acceleration * delta)
func _lerp_dir_to(new_dir:Vector3, lerp_velocity:float)-> void: current_dir = lerp(current_dir, new_dir, lerp_velocity)
	
func _bob_head(delta:float):
	if !is_on_floor():
		current_bob.reset()
		return
	current_bob.update(delta)
	eyes.position = current_bob.bob_vector

func _get_crouch_height() -> float:
	if crouch_collider != null:
		# get the rato of the head height to the collider
		var ratio:float = head_height / collider.shape.height
		return crouch_collider.shape.height * ratio
	return 1.0

func _something_above_head() -> bool:
	if head_ray:
		return head_ray.is_colliding()
	return false
	
#region Tool-Specific Functions
@export_category("")
@export_tool_button("Create Nodes") var create_action = _create

func _create():
	if !is_instance_valid(collider) or collider.owner == null:
		collider = _add_collider(self)
		collider.position.y = 1.0
		collider.debug_color = Color.BLACK
	if !is_instance_valid(head) or head.owner == null:
		neck = _add_n3d(self, "Neck")
		head = _add_n3d(neck,"Head")
		head.position.y = head_height
		eyes = _add_n3d(head,"Eyes")
		camera = _add_camera(eyes, true)
		head_ray = _add_ray(head, "HeadRay")
		head_ray.target_position = Vector3(0, collider.shape.height - head_height + 0.25, 0)
		head_ray.enabled = true

func _add_collider(parent: Node3D, _name:String = "Collider") -> CollisionShape3D:
	collider = CollisionShape3D.new()
	collider.shape = CapsuleShape3D.new()
	parent.add_child(collider)
	collider.name = _name
	collider.owner = get_tree().edited_scene_root
	return collider

func _add_camera(parent:Node3D, is_current:bool = false,  _name:String = "Camera") -> Camera3D:
	var cam = Camera3D.new()
	cam.name = _name
	cam.current = is_current
	parent.add_child(cam)
	cam.owner = get_tree().edited_scene_root
	return cam

func _add_n3d(parent:Node3D, _name:String = "Node3D") -> Node3D:
	var node:Node3D = Node3D.new()
	parent.add_child(node)
	node.name = _name
	node.owner = get_tree().edited_scene_root
	return node

func _add_ray(parent:Node3D, _name:String = "Ray") -> RayCast3D:
	var ray := RayCast3D.new()
	parent.add_child(ray)
	ray.name = _name
	ray.owner = get_tree().edited_scene_root
	return ray

func _add_actions():
	var added_action:bool = false
	
	for event in REQUIRED_ACTIONS:
		var added:bool = _add_action(event)
		# be careful of the short circuit nature of the or operator here!
		added_action = added_action or added
	
	if added_action:
		push_warning("Some required input actions have been added but need actual inputs. Reload the project and check the Input Map.")
		ProjectSettings.save()
	
func _add_action(action_name:String) -> bool:
	if !ProjectSettings.has_setting("input/" + action_name):
		print("Missing action '%s'" % action_name)
		ProjectSettings.set_setting("input/" + action_name, {"deadzone" : 0.2, "events" : []})
		return true
	return false
#endregion
