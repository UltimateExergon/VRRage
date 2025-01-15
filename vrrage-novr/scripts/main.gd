extends Node3D

const levelPath : String = "res://scenes/Level/"

var startPos : Vector3

func _ready():
	load_level("testlevel")
	load_player()
	
func delete_oldLevel():
	print("Deleting old level")
	for i in get_tree().get_nodes_in_group("LEVEL"):
		i.queue_free()
		
func load_level(levelname : String) -> void:
	delete_oldLevel()
	
	print("Loading " + levelname)
	var level = load(levelPath + levelname + ".tscn").instantiate()
	add_child(level)
	startPos = level.get_startPos()
	level.add_to_group("LEVEL")
	
func load_player():
	var player = load("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.position = startPos
	
