extends CharacterBody3D

@export var speed : float = 8.0
@export var crouch_speed : float = 4.0
@export var accel : float = 12.0
@export var jump : float = 5.0
@export var sensitivity : float = 0.2
@export var min_angle : float = -80
@export var max_angle : float = 90
@export var move_speed : float = 5.0

@onready var head = $Head
@onready var raycast = $Head/RayCast3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_rot : Vector2

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	raycast_check()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("SPACE"):
			velocity.y = jump

	var input_dir = Input.get_vector("A", "D", "W", "S")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerp(velocity.x, direction.x * move_speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * move_speed, accel * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, accel * delta)
		velocity.z = lerp(velocity.z, 0.0, accel * delta)

	move_and_slide()
	
	var plat_rot = get_platform_angular_velocity()
	look_rot.y += rad_to_deg(plat_rot.y * delta)
	head.rotation_degrees.x = look_rot.x
	rotation_degrees.y = look_rot.y

func _input(event):
	if Input.is_action_just_pressed("ESC"):
		get_tree().quit()
		
	if event is InputEventMouseMotion:
		look_rot.y -= (event.relative.x * sensitivity)
		look_rot.x -= (event.relative.y * sensitivity)
		look_rot.x = clamp(look_rot.x, min_angle, max_angle)
		
func raycast_check():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		if collider.is_in_group("shadertest"):
			if Input.is_action_just_pressed("E"):
				collider.change_color(Color8(0, 0, 0, 0))
		
		
		if Input.is_action_just_pressed("E"):
			if collider.is_in_group("DESTRUCTIBLE"):
				print("Destructible Object detected")
				collider.get_parent().destroy()
