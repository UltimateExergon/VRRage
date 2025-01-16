extends Node3D

const levelPath : String = "res://scenes/Level/"
const recipePath : String = "res://craftingRecipes/"
const levelFormat : String = ".tscn"
const recipeFormat : String = ".csv"

var startPos : Vector3
var craftingRecipes : Array

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
	craftingRecipes = load(recipePath + levelname + recipeFormat).records
	var level = load(levelPath + levelname + levelFormat).instantiate()
	add_child(level)
	startPos = level.get_startPos()
	level.add_to_group("LEVEL")
	
	for i in get_tree().get_nodes_in_group("DESTRUCTIBLE"):
		i.get_parent().set_currentLevel(levelname)
	
func load_player():
	var player = load("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.position = startPos
	
