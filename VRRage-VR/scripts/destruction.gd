class_name Destruction
extends Node3D

const itemPath : String = "res://scenes/items/"
const itemFormat : String = ".tscn"

@export var fragmented : PackedScene: set = set_fragmented
@export var dropID : String = ""
@export var score_points : int = 100
var shard_container

var current_level : String : set = set_currentLevel

@export_group("Collision")
@export_flags_3d_physics var collision_mask = 1

@export_group("Physics")
@export var explosion_power: float = 1.0
@export var vanish_time : int = 1

@onready var main_node = get_tree().root.get_children()[2]

static var _cached_scenes := {}
static var _cached_shapes := {}

func destroy() -> void:
	self.position = self.get_children()[0].global_position
	
	var shard_holder : Node3D = Node3D.new()
	add_child(shard_holder)
	shard_container = shard_holder
	
	for shard in _get_shards():
		_add_shard(shard)
	
	add_drop()
	add_score_points()
	add_timer()

	self.get_children()[0].queue_free()
	
func add_score_points():
	main_node.increase_score(score_points)

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
	body.global_position = global_transform.origin + original.position
	body.global_rotation = global_rotation
	body.collision_mask = collision_mask
	mesh.scale = original.scale
	shape.scale = original.scale
	shape.shape = _cached_shapes[original]
	mesh.mesh = original.mesh
	body.apply_impulse(_random_direction() * explosion_power,
			-original.position.normalized())
			
func add_drop():
	if dropID != "":
		var item = load(itemPath + current_level + "/" + dropID + itemFormat).instantiate()
		item.set_dropID(dropID)
		print("Spawned Drop at: ", item.global_position)
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
	
	
func _on_body_entered(body: Node) -> void:
	print("BODY ENTERED", body, get_children()[0].linear_velocity.length())
	if get_children()[0].linear_velocity.length() > 1 and body.is_in_group("room"):
		self.destroy()
