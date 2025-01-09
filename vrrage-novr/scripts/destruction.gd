@tool
class_name Destruction
extends Node

@export var fragmented: PackedScene: set = set_fragmented
@onready var shard_container := self #get_node("../../")

@export_group("Collision")
@export_flags_3d_physics var collision_layer = 1
@export_flags_3d_physics var collision_mask = 1

@export_group("Physics")
@export var explosion_power: float = 1.0
@export var vanish_time : int = 10

static var _cached_scenes := {}
static var _cached_shapes := {}

func destroy() -> void:
	for shard in _get_shards():
		_add_shard(shard)
	add_timer()
	get_parent().get_node("toDestroy").queue_free()

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
	body.add_child(mesh)
	body.add_child(shape)
	shard_container.add_child(body, true)
	body.global_position = get_parent().global_transform.origin + original.position
	body.global_rotation = get_parent().global_rotation
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	mesh.scale = original.scale
	shape.scale = original.scale
	shape.shape = _cached_shapes[original]
	mesh.mesh = original.mesh
	body.apply_impulse(_random_direction() * explosion_power,
			-original.position.normalized())
			
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
