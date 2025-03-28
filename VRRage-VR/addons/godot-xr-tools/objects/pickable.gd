class_name XRToolsPickable
extends RigidBody3D


## XR Tools Pickable Object
##
## This script allows a [RigidBody3D] to be picked up by an
## [XRToolsFunctionPickup] attached to a players controller.
##
## Additionally pickable objects may support being snapped into
## [XRToolsSnapZone] areas.
##
## Grab-points can be defined by adding different types of [XRToolsGrabPoint]
## child nodes controlling hand and snap-zone grab locations.


# Signal emitted when this object is picked up (held by a player or snap-zone)
signal picked_up(pickable)

# Signal emitted when this object is dropped
signal dropped(pickable)

# Signal emitted when this object is grabbed (primary or secondary)
signal grabbed(pickable, by)

# Signal emitted when this object is released (primary or secondary)
signal released(pickable, by)

# Signal emitted when the user presses the action button while holding this object
signal action_pressed(pickable)

# Signal emitted when the highlight state changes
signal highlight_updated(pickable, enable)


## Method used to grab object at range
enum RangedMethod {
	NONE,				## Ranged grab is not supported
	SNAP,				## Object snaps to holder
	LERP,				## Object lerps to holder
}

enum ReleaseMode {
	ORIGINAL = -1,		## Preserve original mode when picked up
	UNFROZEN = 0,		## Release and unfreeze
	FROZEN = 1,			## Release and freeze
}

enum SecondHandGrab {
	IGNORE,				## Ignore second grab
	SWAP,				## Swap to second hand
	SECOND,				## Second hand grab
}

@export_category("Item")
@export var objectID : String : get = get_ObjectID ##Identifier of the Objekt, unique
@export var isStatic : bool = false ##Determines, if object can move or not


var collisionLayers : Array = [3] ##Collision Layers of the all pickables and items, leave as is
var collisionMasks : Array = [1, 2, 3, 4] ##Collision Masks of the all pickables and items, leave as is

# Default layer for held objects is 17:held-object
const DEFAULT_LAYER := 0b0000_0000_0000_0001_0000_0000_0000_0000


## If true, the pickable supports being picked up
@export var enabled : bool = true

## If true, the grip control must be held to keep the object picked up
@export var press_to_hold : bool = true

## Layer for this object while picked up
@export_flags_3d_physics var picked_up_layer : int = DEFAULT_LAYER

## Release mode to use when releasing the object
@export var release_mode : ReleaseMode = ReleaseMode.ORIGINAL

## Method used to perform a ranged grab
@export var ranged_grab_method : RangedMethod = RangedMethod.SNAP: set = _set_ranged_grab_method

## Second hand grab mode
@export var second_hand_grab : SecondHandGrab = SecondHandGrab.IGNORE

## Speed for ranged grab
@export var ranged_grab_speed : float = 20.0

## Refuse pick-by when in the specified group
@export var picked_by_exclude : String = ""

## Require pick-by to be in the specified group
@export var picked_by_require : String = ""

## If true, the object can be picked up at range
var can_ranged_grab: bool = true

## Frozen state to restore to when dropped
var restore_freeze : bool = false

# Count of 'is_closest' grabbers
var _closest_count: int = 0

# Grab Driver to control position while grabbed
var _grab_driver: XRToolsGrabDriver = null

# Array of grab points
var _grab_points : Array[XRToolsGrabPoint] = []

# Dictionary of nodes requesting highlight
var _highlight_requests : Dictionary = {}

# Is this node highlighted
var _highlighted : bool = false

#True if node is picked up
var got_picked_up : bool = false


# Remember some state so we can return to it when the user drops the object
var original_collision_mask : int
var original_collision_layer : int

# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPickable"


# Called when the node enters the scene tree for the first time.
func _ready():
	make_meshes_unique()
	get_all_GrabPoints()
	set_Collisions()
	
	original_collision_mask = collision_mask
	original_collision_layer = collision_layer
	
	if isStatic:
		self.set_collision_mask_value(2, false)
		self.set_collision_layer_value(3, false)
		self.set_collision_layer_value(4, true)
		self.lock_rotation = true
		self.can_sleep = false
		
	if !objectID:
		objectID = get_parent_node_3d().name
	
	self.highlight_updated.connect(_highlight_updated)
	
	self.contact_monitor = true
	self.max_contacts_reported = 250
	self.continuous_cd = true
	
	if self.enabled:
		if self.is_in_group("CRAFTABLE"):
			add_outline_shader(Globals.outline_color_crafting)
		else:
			add_outline_shader(Globals.outline_color)
			
func _physics_process(delta: float) -> void:
	if isStatic:
		self.linear_velocity = Vector3.ZERO
		self.angular_velocity = Vector3.ZERO
		self.constant_force = Vector3.ZERO
		
func set_Collisions():
	self.set_collision_layer_value(1, false)
	for i in collisionLayers:
		self.set_collision_layer_value(i, true)
	
	for j in collisionMasks:
		self.set_collision_mask_value(j, true)
		
func get_all_GrabPoints():
	# Get all grab points
	for child in get_children():
		var grab_point := child as XRToolsGrabPoint
		if grab_point:
			_grab_points.push_back(grab_point)
			
func get_ObjectID() -> String:
	return objectID


# Called when the node exits the tree
func _exit_tree():
	# Skip if not picked up
	if not is_instance_valid(_grab_driver):
		return

	# Release primary grab
	if _grab_driver.primary:
		_grab_driver.primary.release()

	# Release secondary grab
	if _grab_driver.secondary:
		_grab_driver.secondary.release()


# Test if this object can be picked up
func can_pick_up(by: Node3D) -> bool:
	# Refuse if not enabled
	if not enabled:
		return false

	# Allow if not held by anything
	if not is_picked_up():
		return true

	# Fail if second hand grabbing isn't allowed
	if second_hand_grab == SecondHandGrab.IGNORE:
		return false

	# Fail if either pickup isn't by a hand
	if not _grab_driver.primary.pickup or not by is XRToolsFunctionPickup:
		return false

	# Allow second hand grab
	return true


# Test if this object is picked up
func is_picked_up() -> bool:
	return _grab_driver and _grab_driver.primary


# action is called when user presses the action button while holding this object
func action():
	# let interested parties know
	emit_signal("action_pressed", self)


## This method requests highlighting of the [XRToolsPickable].
## If [param from] is null then all highlighting requests are cleared,
## otherwise the highlight request is associated with the specified node.
func request_highlight(from : Node, on : bool = true) -> void:
	# Save if we are highlighted
	var old_highlighted := _highlighted

	# Update the highlight requests dictionary
	if not from:
		_highlight_requests.clear()
	elif on:
		_highlight_requests[from] = from
	else:
		_highlight_requests.erase(from)

	# Update the highlighted state
	_highlighted = _highlight_requests.size() > 0

	# Report any changes
	if _highlighted != old_highlighted:
		emit_signal("highlight_updated", self, _highlighted)


func drop():
	# Skip if not picked up
	if not is_picked_up():
		return

	# Request secondary grabber to drop
	if _grab_driver.secondary:
		_grab_driver.secondary.by.drop_object()

	# Request primary grabber to drop
	_grab_driver.primary.by.drop_object()


func drop_and_free():
	drop()
	queue_free()


# Called when this object is picked up
func pick_up(by: Node3D) -> void:
	# Skip if not enabled
	if not enabled:
		#print("TRIED TO PICK UP ", self.name, " BUT ENABLED: ", enabled)
		return

	# Find the grabber information
	var grabber := Grabber.new(by)

	# Test if we're already picked up:
	if is_picked_up():
		# Ignore if we don't support second-hand grab
		if second_hand_grab == SecondHandGrab.IGNORE:
			print_verbose("%s> second-hand grab not enabled" % name)
			return

		# Ignore if either pickup isn't by a hand
		if not _grab_driver.primary.pickup or not grabber.pickup:
			return

		# Construct the second grab
		if second_hand_grab != SecondHandGrab.SWAP:
			# Grab the object
			var by_grab_point := _get_grab_point(by, _grab_driver.primary.point)
			var grab := Grab.new(grabber, self, by_grab_point, true)
			_grab_driver.add_grab(grab)

			# Report the secondary grab
			grabbed.emit(self, by)
			return

		# Swapping hands, let go with the primary grab
		print_verbose("%s> letting go to swap hands" % name)
		let_go(_grab_driver.primary.by, Vector3.ZERO, Vector3.ZERO)

	# Remember the mode before pickup
	match release_mode:
		ReleaseMode.UNFROZEN:
			restore_freeze = false

		ReleaseMode.FROZEN:
			restore_freeze = true

		_:
			restore_freeze = freeze
			
	#print("SAVING RESTORE FREEZE AS: ", restore_freeze)

	got_picked_up = true
	change_color(Globals.outline_color_none)

	# turn off physics on our pickable object
	#freeze = true
	collision_layer = picked_up_layer #17
	set_collision_mask_value(17, true)
	#collision_mask = 0
	#print("SET COLLISION LAYER TO: ", collision_layer, " SET MASK TO: ", collision_mask)

	# Find a suitable primary hand grab
	var by_grab_point := _get_grab_point(by, null)

	# Construct the grab driver
	if by.picked_up_ranged:
		if ranged_grab_method == RangedMethod.LERP:
			var grab := Grab.new(grabber, self, by_grab_point, false)
			_grab_driver = XRToolsGrabDriver.create_lerp(self, grab, ranged_grab_speed)
		else:
			var grab := Grab.new(grabber, self, by_grab_point, false)
			_grab_driver = XRToolsGrabDriver.create_snap(self, grab)
	else:
		var grab := Grab.new(grabber, self, by_grab_point, true)
		_grab_driver = XRToolsGrabDriver.create_snap(self, grab)

	# Report picked up and grabbed
	picked_up.emit(self)
	grabbed.emit(self, by)
	
	#print("SUCCESSFULLY PICKED UP ", self.name, " WITH GOT_PICKED_UP: ", got_picked_up)


# Called when this object is dropped
func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	# Skip if not picked up
	if not is_picked_up():
		return

	# Get the grab information
	var grab := _grab_driver.get_grab(by)
	if not grab:
		return

	# Remove the grab from the driver and release the grab
	_grab_driver.remove_grab(grab)
	grab.release()

	# Test if still grabbing
	if _grab_driver.primary:
		# Test if we need to swap grab-points
		if is_instance_valid(_grab_driver.primary.hand_point):
			# Verify the current primary grab point is a valid primary grab point
			if _grab_driver.primary.hand_point.mode != XRToolsGrabPointHand.Mode.SECONDARY:
				return

			# Find a more suitable grab-point
			var new_grab_point := _get_grab_point(_grab_driver.primary.by, null)
			print_verbose("%s> held only by secondary, swapping grab points" % name)
			switch_active_grab_point(new_grab_point)

		# Grab is still good
		return

	# Drop the grab-driver
	print_verbose("%s> dropping" % name)
	_grab_driver.discard()
	_grab_driver = null
	
	got_picked_up = false

	# Restore RigidBody mode
	#print("RESTORING FREEZE MODE FOR ", self, " TO ", restore_freeze)
	freeze = restore_freeze
	collision_mask = original_collision_mask
	collision_layer = original_collision_layer
	set_collision_mask_value(17, false)
	
	#print("SET COLLISION LAYER TO: ", collision_layer, " SET MASK TO: ", collision_mask)

	# Set velocity
	linear_velocity = p_linear_velocity
	angular_velocity = p_angular_velocity

	# let interested parties know
	dropped.emit(self)
	
	#print("SUCCESSFULLY DROPPED ", self.name, " WITH GOT_PICKED_UP: ", got_picked_up)


## Get the node currently holding this object
func get_picked_up_by() -> Node3D:
	# Skip if not picked up
	if not is_picked_up():
		return null

	# Get the primary pickup
	return _grab_driver.primary.by


## Get the controller currently holding this object
func get_picked_up_by_controller() -> XRController3D:
	# Skip if not picked up
	if not is_picked_up():
		return null

	# Get the primary pickup controller
	return _grab_driver.primary.controller


## Get the active grab-point this object is held by
func get_active_grab_point() -> XRToolsGrabPoint:
	# Skip if not picked up
	if not is_picked_up():
		return null

	return _grab_driver.primary.point


## Switch the active grab-point for this object
func switch_active_grab_point(grab_point : XRToolsGrabPoint):
	# Skip if not picked up
	if not is_picked_up():
		return null

	# Apply the grab point
	_grab_driver.primary.set_grab_point(grab_point)


## Find the most suitable grab-point for the grabber
func _get_grab_point(grabber : Node3D, current : XRToolsGrabPoint) -> XRToolsGrabPoint:
	# Find the best grab-point
	var fitness := 0.0
	var point : XRToolsGrabPoint = null
	for p in _grab_points:
		var f := p.can_grab(grabber, current)
		if f > fitness:
			fitness = f
			point = p

	# Resolve redirection
	while point is XRToolsGrabPointRedirect:
		point = point.target

	# Return the best grab point
	print_verbose("%s> picked grab-point %s" % [name, point])
	return point


func _set_ranged_grab_method(new_value: int) -> void:
	ranged_grab_method = new_value
	can_ranged_grab = new_value != RangedMethod.NONE
	
	
func make_meshes_unique():
	for i in get_children():
		for m in get_meshes():
			var mesh_duplicate = m.mesh.duplicate(true)
			if i is MeshInstance3D:
				i.mesh = mesh_duplicate
	
func get_meshes() -> Array:
	var meshes : Array = []
	for i in get_children():
		if i is MeshInstance3D:
			meshes.append(i)
			
	return meshes
	
func _highlight_updated(body, is_near):
	if not body.got_picked_up:
		if body.is_in_group("CRAFTABLE"):
			if is_near:
				change_color(Globals.outline_color_near)
			else:
				change_color(Globals.outline_color_crafting)
		elif is_near:
			change_color(Globals.outline_color_near)
		else:
			change_color(Globals.outline_color)
	
	
func get_surface_mat(ind : int, object : Node):
	return object.mesh.surface_get_material(ind)
	
func add_outline_shader(color : Color):
	for i in get_meshes():
		var material : Material = get_surface_mat(0, i)
		i.mesh.surface_set_material(0, material.duplicate(true))
		material = get_surface_mat(0, i)
		
		if material.get_next_pass() == null:
			var new_mat : ShaderMaterial = ShaderMaterial.new()
			new_mat.set_shader(Globals.outline_shader)
			new_mat.set_shader_parameter("outline_color", color)
			new_mat.set_shader_parameter("outline_width", Globals.outline_width)
		
			material.set_next_pass(new_mat)
		
func change_color(color : Color):
	for i in get_meshes():
		var shaderMat : ShaderMaterial = get_surface_mat(0, i).get_next_pass()
		shaderMat.set_shader_parameter("outline_color", color)
		
func make_invincible():
	if self.get_parent() is Destruction:
		self.get_parent().start_invincibility_timer()
