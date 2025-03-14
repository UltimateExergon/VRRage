extends Node3D
class_name Destruction

const scoreFloatingDuration : float = 1.5
const scoreTargetLocation : Vector3 = Vector3(0, 1.5, 0)
const spawn_invincibility_time : float = 1.0

@export_category("Destruction")
@export var fragmented : PackedScene: set = set_fragmented ##Destroyed Version of the Mesh
@export var destroyable_by : Array = [] : get = get_destroyableBy ##Only these Objects can destroy the Object, leave empty if all can
@export var hand_destruction : bool = false ##Object can be destroyed by touching it with hand
@export var hits_left : int = 0 ##How many more hits until the object is destroyed
@export var dropID : String = "" ##Scene Name of the Item to drop (- the .tscn)
@export var score_points : int = 100 ##Score Points awarded upon destruction
@export var destroy_everything : bool = false ##Enables the item to destroy EVERYTHING

@export_group("Physics")
@export var explosion_power: float = 1.0 ##How strong the shards are blown away upon destruction

@export_category("Sound")
@export var destructionSound : String = "" ##Filename in assets/sound/sound_effects without .mp3

@export_category("Destruction Particles")
@export var particleAmount : int = 240 ##How many particles to be emitted upon destruction by CPU/GPU Particle Nodes


var particleEmitTime : float = 0.1

var shard_container : Node3D

var current_level : String : set = set_currentLevel

var is_destructible : bool = true

var particleEmitters : Array = []

var can_destroy : bool = true

@onready var main_node = get_tree().root.get_child(Globals.main_order)
@onready var invincible_timer : Timer = Timer.new()
@onready var emitTimer : Timer = Timer.new()
@onready var soundPlayer : AudioStreamPlayer3D = AudioStreamPlayer3D.new()

static var _cached_scenes := {}
static var _cached_shapes := {}

func _ready():
	var body = self.get_child(0)
	body.add_to_group("DESTRUCTIBLE")
	if body is RigidBody3D:
		body.body_entered.connect(_on_body_entered)
		body.contact_monitor = true
		body.max_contacts_reported = 10
		
	var pos = get_rigidBody_position()
	shard_container = Node3D.new()
	add_child(shard_container)
	shard_container.position = pos + Vector3(0,.2,0)
	
	if not fragmented == null:
		for shard in _get_shards():
			_add_shard(shard)
	
	fragmented = null
	
	particleEmitters = check_for_particleEmitters()
	if particleEmitters.is_empty() == false:
		add_emitTimer()
	else:
		add_default_particleEmitter()
	
	add_invincibleTimer()
	add_soundPlayer()
	
func add_default_particleEmitter():
	var default = Globals.default_particleEmitter.instantiate()
	default.emitting = false
	get_child(0).add_child(default)
	
	particleEmitters = check_for_particleEmitters()
	if particleEmitters.is_empty():
		print("Adding default particle emitter failed")
	else:
		add_emitTimer()
	
func add_soundPlayer():
	var audio_stream : AudioStreamMP3
	if not destructionSound == "":
		audio_stream = load(Globals.soundeffectPath + destructionSound + Globals.soundFormat)
	else:
		audio_stream = Globals.default_destruction_sound
		
	soundPlayer.stream = audio_stream
	soundPlayer.volume_db = Globals.volumeDB
	soundPlayer.max_db = Globals.maxDB
	soundPlayer.autoplay = false
	self.get_child(0).add_child(soundPlayer)
	
func add_invincibleTimer():
	invincible_timer.autostart = false
	invincible_timer.one_shot = true
	add_child(invincible_timer)
	invincible_timer.timeout.connect(_on_invincible_timer_timeout)
	
func add_emitTimer():
	emitTimer.autostart = false
	emitTimer.one_shot = true
	add_child(emitTimer)
	emitTimer.timeout.connect(_on_emitTimer_timeout)
	
func get_rigidBody_position() -> Vector3:
	if get_child(0) is RigidBody3D:
		return get_child(0).position
	return Vector3.ZERO

func destroy() -> void:
	if can_destroy:
		soundPlayer.play()

		can_destroy = false
		main_node.add_active_shard(shard_container)

		var saved_velocity = get_child(0).linear_velocity
		start_shards(saved_velocity)

		for i in self.get_child(0).get_children():
			if i is MeshInstance3D or i is CollisionShape3D or i is CollisionPolygon3D:
				i.visible = false

		add_drop(saved_velocity)
		emit_Particles()
		add_floatingScore()
	
		add_score_points()

		await soundPlayer.finished
	
		self.get_child(0).queue_free()
	
func emit_Particles():
	if particleEmitters.is_empty() == false:
		for i in particleEmitters:
			i.one_shot = true
			if not hits_left == 0:
				i.amount = particleAmount / hits_left
			else:
				i.amount = particleAmount
			i.emitting = true
			
		emitTimer.start(particleEmitTime)
	
func check_for_particleEmitters() -> Array:
	var particles : Array = []
	for i in self.get_child(0).get_children():
		if i is GPUParticles3D or i is CPUParticles3D:
			particles.append(i)
			
	return particles
	
func add_floatingScore():
	var destructionScore = Globals.destructionScore.instantiate()
	destructionScore.position = shard_container.position
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
			if shard_mesh is MeshInstance3D:
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
	
	body.set_physics_process(false)
	body.continuous_cd = false
	body.set_collision_layer_value(1, false)
	body.set_collision_mask_value(1, true)
	body.set_collision_mask_value(4, true)
	
	mesh.scale = orig_mesh.scale
	shape.scale = orig_mesh.scale
	shape.shape = _cached_shapes[original]
	mesh.mesh = original.mesh
	
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	body.freeze = true
	body.visible = false
	
func start_shards(old_velocity : Vector3):
	shard_container.position = self.get_child(0).position
	
	for i in shard_container.get_children():
		i.visible = true
		i.freeze = false
		i.set_physics_process(true)
		i.apply_impulse(old_velocity + _random_direction() * explosion_power, -shard_container.position.normalized())
			
func add_drop(old_velocity: Vector3):
	if dropID != "":
		var item = load(Globals.itemPath + current_level + "/" + dropID + Globals.sceneFormat).instantiate()
		
		var rigidBody = get_rigid_body(item)

		item.position = shard_container.position
		print("Spawned Drop ", dropID, " at ", item.position)
		
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
	var id = body.get_ObjectID()
	
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
	var rigidBody = get_child(0)
	var enteringRigidBody = get_rigid_body(body)
	
	var enteringLinearSpeed
	var enteringAngularSpeed

	if rigidBody is not XRToolsPickable:
		return
	
	if rigidBody.got_picked_up == false and is_destructible == true:
		if enteringRigidBody and body.get_parent() is Destruction:
			enteringLinearSpeed = enteringRigidBody.linear_velocity.length()
			enteringAngularSpeed = enteringRigidBody.angular_velocity.length()
			if (enteringLinearSpeed > 4) or (enteringAngularSpeed > 20):
				if destroyable_by.size() > 0:
					if check_destroyable(body):
						check_hits_left()
				if body.get_parent().destroy_everything:
					check_hits_left()
		elif body.is_in_group("hand") and hand_destruction == true and destroyable_by.size() == 0:
			check_hits_left()
		elif rigidBody.linear_velocity.length() > 2 and body.is_in_group("room") and destroyable_by.size() == 0:
			check_hits_left()

func check_hits_left():
	if hits_left == 0:
		self.destroy()
	else:
		emit_Particles()
		hits_left -= 1
			
func _on_invincible_timer_timeout():
	is_destructible = true
	
func _on_emitTimer_timeout():
	for i in particleEmitters:
		if is_instance_valid(i):
			i.emitting = false
			
