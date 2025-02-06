class_name Destruction
extends Node3D

const scoreFloatingDuration : float = 3.0
const scoreTargetLocation : Vector3 = Vector3(0, 1, 0)

@export var fragmented : PackedScene: set = set_fragmented
@export var destroyable_by : Array = [] : get = get_destroyableBy
@export var hand_destruction : bool = false
@export var dropID : String = ""
@export var score_points : int = 100

var shard_container : Node3D

var current_level : String : set = set_currentLevel

var linear_velocity : float

@export_group("Collision")
@export_flags_3d_physics var collision_mask = 1

@export_group("Physics")
@export var explosion_power: float = 1.0
@export var vanish_time : int = 5

@onready var main_node = get_tree().root.get_children()[Globals.main_order]

static var _cached_scenes := {}
static var _cached_shapes := {}

func _ready():
	var body = get_children()[0]
	body.add_to_group("DESTRUCTIBLE")
	body.body_entered.connect(_on_body_entered)
	
func _physics_process(_delta: float) -> void:
	if get_children()[0] is RigidBody3D:
		linear_velocity = get_children()[0].linear_velocity.length()

func destroy() -> void:
	self.position = self.get_children()[0].global_position
	var saved_velocity = self.get_children()[0].linear_velocity
	
	shard_container = Node3D.new()
	add_child(shard_container)
	main_node.add_active_shard(shard_container)
	
	for shard in _get_shards():
		_add_shard(shard, saved_velocity)
	
	add_drop(saved_velocity)
	add_score_points()
	add_floatingScore()
	#add_timer()
	
	self.get_children()[0].queue_free()
	
func add_floatingScore():
	var destructionScore = Globals.destructionScore.instantiate()
	add_child(destructionScore)
	destructionScore.text = "+" + str(score_points)
	
	var tween = get_tree().create_tween()
	var tween_pos = self.position + scoreTargetLocation
	print(self.position, tween_pos)
	tween.tween_property(destructionScore, "position", tween_pos, scoreFloatingDuration)
	
func get_destroyableBy() -> Array:
	return destroyable_by
	
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

func _add_shard(original: MeshInstance3D, old_velocity: Vector3) -> void:
	var body := RigidBody3D.new()
	var mesh := MeshInstance3D.new()
	var shape := CollisionShape3D.new()
	body.add_child(mesh)
	body.add_child(shape)
	shard_container.add_child(body, true)
	body.global_position = global_transform.origin + original.position
	body.global_rotation = global_rotation
	body.collision_layer = 0
	body.collision_mask = collision_mask
	body.set_collision_mask_value(4, true)
	mesh.scale = original.scale
	shape.scale = original.scale
	shape.shape = _cached_shapes[original]
	mesh.mesh = original.mesh
	body.apply_impulse(old_velocity + _random_direction() * explosion_power,
			-original.position.normalized())
			
func add_drop(old_velocity: Vector3):
	if dropID != "":
		var item = load(Globals.itemPath + current_level + "/" + dropID + Globals.itemFormat).instantiate()
		
		var rigidBody = get_rigid_body(item)
		rigidBody.set_dropID(dropID)
		
		add_child(item)
		rigidBody.linear_velocity = old_velocity
		
func get_rigid_body(node: Node) -> RigidBody3D:
	if node is RigidBody3D:
		return node
		
	for child in node.get_children():
		if child is RigidBody3D:
			return child
		else:
			if child.get_child_count() > 0:
				return get_rigid_body(child)
	return null
		
func check_destroyable(body) -> bool:
	var id = body.objectID
	
	for i in destroyable_by:
		if i == id:
			return true
			
	return false
		
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
	
func _on_body_entered(body: Node):
	var rigidBody = get_children()[0]
	var enteringRigidBody = get_rigid_body(body)

	print(body.name)

	if !rigidBody.got_picked_up:
		if destroyable_by.size() > 0 and !body.is_in_group("room"):
			if check_destroyable(body) and enteringRigidBody.linear_velocity.length() > 5:
				self.destroy()
		elif rigidBody.linear_velocity.length() > 1 and body.is_in_group("room"):
				self.destroy()
		elif body.is_in_group("hand") and hand_destruction == true:
			self.destroy()
