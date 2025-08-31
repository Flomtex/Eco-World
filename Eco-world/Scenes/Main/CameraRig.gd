extends Node3D

@export var move_speed: float = 12.0        # units/sec
@export var rotate_speed_deg: float = 90.0  # yaw deg/sec
@export var fov_step: float = 3.0
@export var fov_min: float = 30.0
@export var fov_max: float = 90.0


@onready var camera_3d: Camera3D = $Camera3D

func _ready() -> void:
	camera_3d.current = true

func _process(delta: float) -> void:
	# Forward/back with arrow keys (NO strafing).
	var forward_axis := 0.0
	if Input.is_action_pressed("ui_up"):
		forward_axis += 1.0
	if Input.is_action_pressed("ui_down"):
		forward_axis -= 1.0
	if forward_axis != 0.0:
		# Take the camera's forward, flatten to XZ, move in world space
		var forward_dir: Vector3 = -global_transform.basis.z
		forward_dir.y = 0.0
		forward_dir = forward_dir.normalized()
		global_position += forward_dir * (move_speed * delta * forward_axis)
		
	# Rotate left/right (yaw) with arrow keys.
	var yaw_axis := 0.0
	if Input.is_action_pressed("ui_left"):
		yaw_axis += 1.0
	if Input.is_action_pressed("ui_right"):
		yaw_axis -= 1.0
	if yaw_axis != 0.0:
		rotate_y(deg_to_rad(rotate_speed_deg * yaw_axis * delta))

func _unhandled_input(event: InputEvent) -> void:
	# Mouse wheel / two-finger trackpad scroll = zoom (FOV)
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_3d.fov = clamp(camera_3d.fov - fov_step, fov_min, fov_max)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_3d.fov = clamp(camera_3d.fov + fov_step, fov_min, fov_max)
