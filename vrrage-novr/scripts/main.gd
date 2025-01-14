extends Node3D

const levelPath : String = "res://scenes/Level/"

var startPos : Vector3

func _ready():
	load_level("testlevel")
	load_player()
	
func load_level(levelname : String):
	var level = load(levelPath + levelname + ".tscn").instantiate()
	startPos = level.get_startPos()
	add_child(level)
	
func load_player():
	var player = load("res://scenes/player.tscn").instantiate()
	player.position = startPos
	add_child(player)
	
