extends Node3D

signal focus_lost
signal focus_gained
signal pose_recentered

const max_shards : int = 40
const teleport_cooldown : float = 0.5
const loadingLabel_Visibility_Time : float = 5.0
const level_time : float = 60.0

var xr_interface : OpenXRInterface
var xr_is_focussed = false

var current_level : String
var startPos : Vector3
var craftingRecipes : Array
var ingredients : Array

var current_score : int = 0
var score_multiplier : float = 1.0
var score_label = ""
var multiplier_timer : Timer

var player

var active_shards : Array = []

var teleport_timer : Timer
var can_teleport : bool = true

var loading : bool = false
var path_to_level : String = ""

var loadingScreenTimer : Timer
var levelTimer : Timer

var levelTimerAlertSound : AudioStreamPlayer
var craftingSound : AudioStreamPlayer

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
		
		add_teleportTimer()
		add_multiplierTimer()
		add_loadingScreenTimer()
		add_levelTimer()
		add_levelTimerAlertSound()
		add_craftingSound()
		
	else:
		# We couldn't start OpenXR.
		print("OpenXR not instantiated!")
		get_tree().quit()
		
func _process(_delta):
	if loading == true:
		#3 = Loading finished; 2 Loading failed; 1 = in progress, 0 = invalid resource
		var loading_status = ResourceLoader.load_threaded_get_status(path_to_level)
		match loading_status:
			2:
				print("LOADING LEVEL FAILED")
			3:
				print("LOADING SUCCESSFUL")
				switch_level()
		
	if current_level != "level_select" and is_instance_valid(score_label):
		if !multiplier_timer.is_stopped():
			score_label.update_score(current_score, score_multiplier, levelTimer.time_left, multiplier_timer.time_left)
		else:
			score_label.update_score(current_score, score_multiplier, levelTimer.time_left)
			
		if levelTimer.time_left <= 10.0 and levelTimerAlertSound.playing == false:
			levelTimerAlertSound.play()
			
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
func add_levelTimer():
	levelTimer = Timer.new()
	levelTimer.autostart = false
	add_child(levelTimer)
	teleport_timer.timeout.connect(_on_level_timer_timeout)
	teleport_timer.one_shot = true
	
func add_levelTimerAlertSound():
	levelTimerAlertSound = AudioStreamPlayer.new()
	levelTimerAlertSound.stream = Globals.levelTimerAlertSound
	levelTimerAlertSound.volume_db = Globals.volumeDB
	levelTimerAlertSound.autoplay = false
	add_child(levelTimerAlertSound)
	
func add_craftingSound():
	craftingSound = AudioStreamPlayer.new()
	craftingSound.stream = Globals.craftingSound
	craftingSound.volume_db = Globals.volumeDB
	craftingSound.autoplay = false
	add_child(craftingSound)
	
func add_teleportTimer():
	teleport_timer = Timer.new()
	add_child(teleport_timer)
	teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	teleport_timer.one_shot = true
	
func add_multiplierTimer():
	multiplier_timer = Timer.new()
	add_child(multiplier_timer)
	multiplier_timer.timeout.connect(_on_multiplier_timer_timeout)
	multiplier_timer.one_shot = true
	
func add_loadingScreenTimer():
	loadingScreenTimer = Timer.new()
	add_child(loadingScreenTimer)
	loadingScreenTimer.timeout.connect(_on_loadingScreen_timer_timeout)
	loadingScreenTimer.one_shot = true
		
func add_active_shard(shard : Node):
	active_shards.append(shard)
	
	while active_shards.size() > max_shards:
		if is_instance_valid(active_shards[0]):
			active_shards[0].queue_free()
		active_shards.remove_at(0)
		
func get_score_multiplier() -> float:
	return score_multiplier
		
func delete_oldLevel():
	print("Deleting old level")

	for i in get_tree().get_nodes_in_group("LEVEL"):
		i.queue_free()
		
func load_level(levelname : String) -> void:
	print("Loading " + levelname)
	
	if current_level:
		Globals.update_highscore(current_score, current_level)
	
	current_level = levelname
	path_to_level = Globals.levelPath + current_level + Globals.sceneFormat
	ResourceLoader.load_threaded_request(path_to_level)
	loading = true
	if player:
		switch_loadingLabel_Visibility()
		enable_teleport(false)
		
func switch_level():
	#print("Switching to ", current_level)
	delete_oldLevel()
	
	current_score = 0
	score_multiplier = 1.0
	multiplier_timer.stop()
	
	var level = ResourceLoader.load_threaded_get(path_to_level)
	level = level.instantiate()
	add_child(level)
	
	if current_level != "level_select":
		craftingRecipes = load(Globals.recipePath + current_level + Globals.recipeFormat).records
		score_label = get_node(current_level + "/Score")
		
	startPos = level.get_startPos()
	level.add_to_group("LEVEL")
	
	for i in get_tree().get_nodes_in_group("DESTRUCTIBLE"):
		i.get_parent().set_currentLevel(current_level)
		
		
	loadingScreenTimer.start(loadingLabel_Visibility_Time)
		
func enable_teleport(tp : bool):
	for j in get_tree().get_nodes_in_group("teleport"):
		j.enabled = tp
		
func switch_loadingLabel_Visibility():
	player.get_node("XRCamera3D/LoadingLabel").visible = !player.get_node("XRCamera3D/LoadingLabel").visible
	
func load_player() -> void:
	print("Loading Player")
	player = load("res://scenes/player.tscn").instantiate()
	teleport_player()
	add_child(player)
	
	if current_level != "level_select":
		increase_score(0)
	
func teleport_player():
	player.global_position = startPos
	
func set_timed_multiplier(multiplier : float, m_time : float):
	#print("SCORE MULTIPLIER SET TO: ", multiplier, " FOR: ", m_time, " SECONDS")
	score_multiplier = multiplier
	score_label.update_score(current_score, score_multiplier)
	multiplier_timer.start(m_time)
	
func craft(item1, item2):
	print("ZU TESTENDE ITEMS ", item1.get_ObjectID(), " ", item2.get_ObjectID())
	ingredients.append([item1.get_ObjectID(), item2.get_ObjectID()])
	#print("INGREDIENTS ", ingredients)
	if ingredients.size() == 2:
		var new_item = match_items()
		if new_item != null:
			spawn_crafted_item(new_item, item1.global_position)
			item1.queue_free()
			item2.queue_free()
		else: 
			item1.collision_reported = false
			item2.collision_reported = false
		ingredients.clear()
			
func spawn_crafted_item(itemID : String, pos : Vector3):
	#print("SPAWN ITEM ", itemID, " FROM ", Globals.itemPath + current_level + "/" + itemID + Globals.sceneFormat)
	var item = load(Globals.itemPath + current_level + "/" + itemID + Globals.sceneFormat).instantiate()
	item.global_position = pos
	get_node(current_level).add_child(item)
	
	craftingSound.play()
	
	# Instantly get picked up
	var rightHand = $Player/RightHand/RightHand/FunctionPickup
	rightHand._pick_up_object(item.get_children()[0])
		
func check_for_recipe(items : Array):
	for i in craftingRecipes:
		var recipe_ingredients : Array = [i[0], i[1]]
		if (items[0] == recipe_ingredients[0] or items[0] == recipe_ingredients[1]) and (items[1] == recipe_ingredients[0] or items[1] == recipe_ingredients[1]):
			return i[2]
			
	return null
		
func match_items():
	var item1 : Array = ingredients[0]
	var item2 : Array = ingredients[1]
	#print("MATCH ", item1, " AND ", item2)
	
	if item1[0] == item2[1] and item1[1] == item2[0]:
		return check_for_recipe(item1)
	else:
		return null
		
func increase_score(points : int):
	current_score += points * score_multiplier
	score_label.update_score(current_score, score_multiplier)
	
func activate_teleport_timer():
	can_teleport = false
	teleport_timer.start(teleport_cooldown)
	
func _on_teleport_timer_timeout():
	can_teleport = true
	
func _on_multiplier_timer_timeout():
	score_multiplier = 1.0
	#print("SCORE MULTIPLIER RESET TO: ", score_multiplier)
	
func _on_loadingScreen_timer_timeout():
	switch_loadingLabel_Visibility()
	enable_teleport(true)
	levelTimer.start(level_time)
	
func _on_level_timer_timeout():
	levelTimerAlertSound.stop()
	load_level("level_select")
	

# Handle OpenXR session ready
func _on_openxr_session_begun() -> void:
	load_level("level_select")
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
	
# Handle OpenXR stopping state
func _on_openxr_stopping() -> void:
	# Our session is being stopped.
	print("OpenXR is stopping")

# Handle OpenXR pose recentered signal
func _on_openxr_pose_recentered() -> void:
	# User recentered view, we have to react to this by recentering the view.
	# This is game implementation dependent.
	emit_signal("pose_recentered")
	
# Test if a given node is of the specified class
func is_xr_class(node : Node, type : String) -> bool:
	if node.has_method("is_xr_class"):
		if node.is_xr_class(type):
			return true
		
	return node.is_class(type)
