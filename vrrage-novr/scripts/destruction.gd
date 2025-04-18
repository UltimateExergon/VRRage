class_name Destruction
extends Node3D

const itemPath : String = "res://scenes/items/"
const itemFormat : String = ".tscn"

@export var fragmented : PackedScene: set = set_fragmented
@export var dropID : int = -1
var shard_container

var current_level : String : set = set_currentLevel

@export_group("Collision")
@export_flags_3d_physics var collision_layer = 1
@export_flags_3d_physics var collision_mask = 1

@export_group("Physics")
@export var explosion_power: float = 1.0
@export var vanish_time : int = 10

static var _cached_scenes := {}
static var _cached_shapes := {}

func _ready() -> void:
	var pos = get_rigidBody_position()
	shard_container = Node3D.new()
	add_child(shard_container)
	shard_container.position = pos + Vector3(0,.2,0)
	
	if not fragmented == null:
		for shard in _get_shards():
			_add_shard(shard)

func destroy() -> void:
	#self.position = self.get_children()[0].global_position
		
	var saved_velocity = get_child(0).linear_velocity
	start_shards(saved_velocity)
		
	add_drop()
	add_timer()
	self.get_children()[0].queue_free()

func _get_shards() -> Array[Node]:
	if not fragmented in _cached_scenes:
		_cached_scenes[fragmented] = fragmented.instantiate()
		for shard_mesh in _cached_scenes[fragmented].get_children():
			_cached_shapes[shard_mesh] = shard_mesh.mesh.create_convex_shape()
	return (_cached_scenes[fragmented].get_children() as Array)\
			.filter(func(node): return node is MeshInstance3D)
	
func set_fragmented(to: PackedScene) -> void:
	fragmented = to
	if is_inside_tree():
		get_tree().node_configuration_warning_changed.emit(self)

func _get_configuration_warnings() -> PackedStringArray:
	return ["No fragmented version set"] if not fragmented else []

func _add_shard(original: MeshInstance3D) -> void:
	var body := RigidBody3D.new()
	var mesh := MeshInstance3D.new()
	var shape := CollisionShape3D.new()
	var orig_mesh = get_child(0).get_children()[0]
	
	body.add_child(mesh)
	body.add_child(shape)
	shard_container.add_child(body, true)
	
	#body.global_position = shard_container.global_position
	body.global_rotation = global_rotation
	
	body.set_collision_layer_value(1, false)
	body.set_collision_mask_value(1, true)
	body.set_collision_mask_value(4, true)
	#body.continuous_cd = true
	
	mesh.scale = orig_mesh.scale
	shape.scale = orig_mesh.scale
	shape.shape = _cached_shapes[original]
	mesh.mesh = original.mesh
	
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	body.freeze = true
	body.visible = false
	
func start_shards(old_velocity : Vector3):
	shard_container.position = self.get_child(0).position
	print("SELF POS: ", self.position, " CONTAINER POS: ", shard_container.position, " CONTAINER GLOBAL POS: ", shard_container.global_position)
	for i in shard_container.get_children():
		#i.position = shard_container.position
		print("Spawing Shard at ", i.position)
		i.visible = true
		i.freeze = false
		i.apply_impulse(old_velocity + _random_direction() * explosion_power, -shard_container.position.normalized())
		
func get_rigidBody_position() -> Vector3:
	if get_child(0) is RigidBody3D:
		return get_child(0).position
	return Vector3.ZERO
		
func add_drop():
	if dropID > -1:
		var item = load(itemPath + current_level + "/" + str(dropID) + itemFormat).instantiate()
		item.set_dropID(dropID)
		add_child(item)
		
func set_currentLevel(levelname : String) -> void:
	current_level = levelname
		
func add_timer():
	var timer : Timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start(vanish_time)
	print("Timer started")
	
func _on_timer_timeout():
	print("Timeout")
	shard_container.queue_free()

static func _random_direction() -> Vector3:
	return (Vector3(randf(), randf(), randf()) - Vector3.ONE / 2.0).normalized() * 2.0
