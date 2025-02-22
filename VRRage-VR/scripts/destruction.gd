extends Node3D
class_name Destruction

const scoreFloatingDuration : float = 1.5
const scoreTargetLocation : Vector3 = Vector3(0, 1.5, 0)
const spawn_invincibility_time : float = 1.0

@export var fragmented : PackedScene: set = set_fragmented ##Destroyed Version of the Mesh
@export var destroyable_by : Array = [] : get = get_destroyableBy ##Only these Objects can destroy the Object, leave empty if all can
@export var hand_destruction : bool = false ##Object can be destroyed by touching it with hand
@export var dropID : String = "" ##Scene Name of the Item to drop (- the .tscn)
@export var score_points : int = 100 ##Score Points awarded upon destruction

var shard_container : Node3D

var current_level : String : set = set_currentLevel

var linear_velocity : float

var is_destructible : bool = true

var body_position : Vector3

@export_group("Physics")
@export var explosion_power: float = 1.0 ##How strong the shards are blown away upon destruction

@onready var main_node = get_tree().root.get_children()[Globals.main_order]
@onready var invincible_timer : Timer = Timer.new()

static var _cached_scenes := {}
static var _cached_shapes := {}

func _ready():
	print(self)
	var body = get_children()[0]
	body.add_to_group("DESTRUCTIBLE")
	body.body_entered.connect(_on_body_entered)
	body.contact_monitor = true
	body.max_contacts_reported = 10
	
	invincible_timer.autostart = false
	invincible_timer.one_shot = true
	add_child(invincible_timer)
	invincible_timer.timeout.connect(_on_invincible_timer_timeout)
	
func _physics_process(_delta: float) -> void:
	if get_children()[0] is RigidBody3D:
		linear_velocity = get_children()[0].linear_velocity.length()
		
func get_rigidBody_position() -> Vector3:
	if get_child(0) is RigidBody3D:
		return get_child(0).position
	return Vector3.ZERO

func destroy() -> void:
	body_position = get_rigidBody_position()
	shard_container = Node3D.new()
	add_child(shard_container)
	main_node.add_active_shard(shard_container)
	
	var pos = get_rigidBody_position()
	#print("Destruction Node Position During Destruction: ", self.position)
	shard_container.position = pos + Vector3(0,.2,0)
	#print("Moved Destruction Node to: ", self.position)
	#print("Spawned Shard Container at: ", shard_container.position)

	var saved_velocity = self.get_children()[0].linear_velocity

	if not fragmented == null:
		for shard in _get_shards():
			_add_shard(shard, saved_velocity)

	add_drop(saved_velocity)
	add_floatingScore()
	
	add_score_points()

	self.get_children()[0].queue_free()
	
func add_floatingScore():
	var destructionScore = Globals.destructionScore.instantiate()
	destructionScore.position = body_position
	#print("Spawning Floating Score at: ", destructionScore.position)
	add_child(destructionScore)
	
	var score : int = score_points * main_node.get_score_multiplier()
	destructionScore.text = "+" + str(score)
	
	var tween = get_tree().create_tween()
	var tween_pos = destructionScore.position + scoreTargetLocation

	tween.tween_property(destructionScore, "position", tween_pos, scoreFloatingDuration)
	tween.tween_callback(destructionScore.queue_free)
	
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
	body.global_position = shard_container.global_position
	body.global_rotation = global_rotation
	body.set_collision_layer_value(1, false)
	body.set_collision_mask_value(1, true)
	body.set_collision_mask_value(4, true)
	body.continuous_cd = true
	mesh.scale = original.scale
	shape.scale = original.scale
	shape.shape = _cached_shapes[original]
	mesh.mesh = original.mesh
	body.apply_impulse(old_velocity + _random_direction() * explosion_power,
			-shard_container.position.normalized())
			
func add_drop(old_velocity: Vector3):
	if dropID != "":
		var item = load(Globals.itemPath + current_level + "/" + dropID + Globals.sceneFormat).instantiate()
		
		var rigidBody = get_rigid_body(item)
		
		item.position = body_position
		print("Spawned Drop at: ", item.position)
		
		add_child(item)
		rigidBody.make_invincible()
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
	if body is not XRToolsPickable:
		return false
	var id = body.objectID
	
	for i in destroyable_by:
		if i == id:
			return true
			
	return false
		
func set_currentLevel(levelname : String) -> void:
	current_level = levelname
	
func start_invincibility_timer():
	is_destructible = false
	#print("Start Timer")
	await get_tree().create_timer(spawn_invincibility_time).timeout
	is_destructible = true

static func _random_direction() -> Vector3:
	return (Vector3(randf(), randf(), randf()) - Vector3.ONE / 2.0).normalized() * 2.0
	
func _on_body_entered(body: Node):
	var rigidBody = get_children()[0]
	var enteringRigidBody = get_rigid_body(body)

	if rigidBody.got_picked_up == false and is_destructible == true:
		if destroyable_by.size() > 0 and !body.is_in_group("room"):
			if check_destroyable(body) and enteringRigidBody.linear_velocity.length() > 5:
				self.destroy()
		elif body.is_in_group("hand") and hand_destruction == true:
			self.destroy()
		elif rigidBody.linear_velocity.length() > 3 and body.is_in_group("room"):
				self.destroy()
			
func _on_invincible_timer_timeout():
	is_destructible = true
			
