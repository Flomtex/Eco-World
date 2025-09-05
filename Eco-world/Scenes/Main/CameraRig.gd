extends Node3D
class_name CameraRig

## Clean camera controller for observing the ecosystem simulation.
## Provides smooth movement and zoom controls with configurable parameters.

@export_group("Movement")
@export var movement_speed: float = 12.0  # Units per second
@export var rotation_speed_degrees: float = 90.0  # Degrees per second

@export_group("Zoom Controls")
@export var zoom_step: float = 3.0
@export var zoom_min_fov: float = 30.0
@export var zoom_max_fov: float = 90.0

# Component references
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	_initialize_camera()

func _initialize_camera() -> void:
	if camera:
		camera.current = true
	else:
		push_error("CameraRig: Camera3D child not found")

func _process(delta: float) -> void:
	_handle_movement_input(delta)
	
func _unhandled_input(event: InputEvent) -> void:
	_handle_zoom_input(event)

func _handle_movement_input(delta: float) -> void:
	var movement_input = _get_movement_input()
	var rotation_input = _get_rotation_input()
	
	# Apply forward/backward movement
	if movement_input != 0.0:
		var forward_direction = -global_transform.basis.z
		forward_direction.y = 0.0  # Keep movement horizontal
		forward_direction = forward_direction.normalized()
		
		global_position += forward_direction * movement_speed * movement_input * delta
	
	# Apply rotation
	if rotation_input != 0.0:
		var rotation_radians = deg_to_rad(rotation_speed_degrees * rotation_input * delta)
		rotate_y(rotation_radians)

func _get_movement_input() -> float:
	var movement = 0.0
	
	if Input.is_action_pressed("ui_up"):
		movement += 1.0
	if Input.is_action_pressed("ui_down"):
		movement -= 1.0
	
	return movement

func _get_rotation_input() -> float:
	var rotation = 0.0
	
	if Input.is_action_pressed("ui_left"):
		rotation += 1.0  # Rotate left (positive Y rotation)
	if Input.is_action_pressed("ui_right"):
		rotation -= 1.0  # Rotate right (negative Y rotation)
	
	return rotation

func _handle_zoom_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not camera:
		return
	
	var mouse_event = event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	
	match mouse_event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(-zoom_step)  # Zoom in (decrease FOV)
		MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(zoom_step)   # Zoom out (increase FOV)

func _adjust_zoom(fov_delta: float) -> void:
	var new_fov = camera.fov + fov_delta
	camera.fov = clamp(new_fov, zoom_min_fov, zoom_max_fov)

## Programmatically set camera position (useful for testing/debugging)
func set_camera_position(position: Vector3) -> void:
	global_position = position

## Programmatically set camera rotation (useful for testing/debugging)
func set_camera_rotation(rotation_degrees: Vector3) -> void:
	rotation_degrees = Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y), 
		deg_to_rad(rotation_degrees.z)
	)

## Get current camera transform for external systems
func get_camera_transform() -> Transform3D:
	return camera.global_transform if camera else Transform3D()

## Set field of view directly
func set_field_of_view(fov_degrees: float) -> void:
	if camera:
		camera.fov = clamp(fov_degrees, zoom_min_fov, zoom_max_fov)
