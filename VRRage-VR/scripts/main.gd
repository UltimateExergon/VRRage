extends Node3D

signal focus_lost
signal focus_gained
signal pose_recentered

const levelPath : String = "res://scenes/Level/"
const itemPath : String = "res://scenes/items/"
const recipePath : String = "res://craftingRecipes/"
const levelFormat : String = ".tscn"
const itemFormat : String = ".tscn"
const recipeFormat : String = ".csv"

@export var maximum_refresh_rate : int = 90

var xr_interface : OpenXRInterface
var xr_is_focussed = false

var current_level : String
var startPos : Vector3
var craftingRecipes : Array
var ingredients : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR instantiated successfully.")
		var vp : Viewport = get_viewport()

		# Enable XR on our viewport
		vp.use_xr = true

		# Make sure v-sync is off, v-sync is handled by OpenXR
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Enable VRS
		if RenderingServer.get_rendering_device():
			vp.vrs_mode = Viewport.VRS_XR
		elif int(ProjectSettings.get_setting("xr/openxr/foveation_level")) == 0:
			push_warning("OpenXR: Recommend setting Foveation level to High in Project Settings")

		# Connect the OpenXR events
		xr_interface.session_begun.connect(_on_openxr_session_begun)
		xr_interface.session_visible.connect(_on_openxr_visible_state)
		xr_interface.session_focussed.connect(_on_openxr_focused_state)
		xr_interface.session_stopping.connect(_on_openxr_stopping)
		xr_interface.pose_recentered.connect(_on_openxr_pose_recentered)
	else:
		# We couldn't start OpenXR.
		print("OpenXR not instantiated!")
		get_tree().quit()
		
func delete_oldLevel():
	print("Deleting old level")
	for i in get_tree().get_nodes_in_group("LEVEL"):
		i.queue_free()
		
func load_level(levelname : String) -> void:
	delete_oldLevel()
	
	print("Loading " + levelname)
	current_level = levelname
	craftingRecipes = load(recipePath + levelname + recipeFormat).records
	var level = load(levelPath + levelname + ".tscn").instantiate()
	add_child(level)
	startPos = level.get_startPos()
	level.add_to_group("LEVEL")

	for i in get_tree().get_nodes_in_group("DESTRUCTIBLE"):
		i.get_parent().set_currentLevel(levelname)
	
func load_player() -> void:
	print("Loading Player")
	var player = load("res://scenes/player.tscn").instantiate()
	player.global_position = startPos
	add_child(player)
	
func craft(item1, item2):
	ingredients.append([item1.get_dropID(), item2.get_dropID()])
	print("ATTEMTPING TO CRAFT WITH INGREDIENTS: ", ingredients)
	if ingredients.size() == 2:
		var new_item = match_items()
		if new_item != null:
			print("CRAFTING RECIPE FOUND, PERFORMING CRAFT OF ITEM: ", new_item)
			spawn_crafted_item(new_item, item1.global_position)
			item1.queue_free()
			item2.queue_free()
		else: 
			print("NO RECIPE FOUND FOR: ", ingredients)
			item1.collision_reported = false
			item2.collision_reported = false
			ingredients.clear()
			
func spawn_crafted_item(itemID : int, pos : Vector3):
	var item = load(itemPath + current_level + "/" + str(itemID) + itemFormat).instantiate()
	item.global_position = pos
	print("CRAFTED NEW ITEM AT POSITION: ", item.global_position)
	get_node(current_level).add_child(item)
		
func check_for_recipe(items : Array):
	print("CHECKING FOR RECIPES WITH ITEMS: ", items)
	for i in craftingRecipes:
		print("CHECKING RECIPE: ", i)
		var recipe_ingredients : Array = [i[0], i[1]]
		print("INGREDIENTS: ", recipe_ingredients)
		if items[0] in recipe_ingredients and items[1] in recipe_ingredients:
			print("RETURNING RECIPE RESULT: ", i[2])
			return i[2]
			
	return null
		
func match_items():
	var item1 : Array = ingredients[0]
	var item2 : Array = ingredients[1]
	
	print("MATCHING ITEMS: ", item1, item2)
	
	if item1[0] == item2[1] and item1[1] == item2[0]:
		return check_for_recipe(item1)
	else:
		return null
	

# Handle OpenXR session ready
func _on_openxr_session_begun() -> void:
	load_level("testlevel")
	load_player()
	
# Handle OpenXR visible state
func _on_openxr_visible_state() -> void:
	# We always pass this state at startup,
	# but the second time we get this it means our player took off their headset
	if xr_is_focussed:
		print("OpenXR lost focus")

		xr_is_focussed = false

		# pause our game
		get_tree().paused = true

		emit_signal("focus_lost")

# Handle OpenXR focused state
func _on_openxr_focused_state() -> void:
	print("OpenXR gained focus")
	xr_is_focussed = true

	# unpause our game
	get_tree().paused = false

	emit_signal("focus_gained")
	
	$Player/OpenXRCompositionLayerQuad.run = true

# Handle OpenXR stopping state
func _on_openxr_stopping() -> void:
	# Our session is being stopped.
	print("OpenXR is stopping")

# Handle OpenXR pose recentered signal
func _on_openxr_pose_recentered() -> void:
	# User recentered view, we have to react to this by recentering the view.
	# This is game implementation dependent.
	emit_signal("pose_recentered")
