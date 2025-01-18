extends Node3D

const levelPath : String = "res://scenes/Level/"
const itemPath : String = "res://scenes/items/"
const recipePath : String = "res://craftingRecipes/"
const levelFormat : String = ".tscn"
const itemFormat : String = ".tscn"
const recipeFormat : String = ".csv"

var current_level : String
var startPos : Vector3
var craftingRecipes : Array
var ingredients : Array

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
	current_level = levelname
	craftingRecipes = load(recipePath + levelname + recipeFormat).records
	var level = load(levelPath + levelname + levelFormat).instantiate()
	add_child(level)
	startPos = level.get_startPos()
	level.add_to_group("LEVEL")
	
	for i in get_tree().get_nodes_in_group("DESTRUCTIBLE"):
		i.get_parent().set_currentLevel(levelname)
	
func load_player():
	var player = load("res://scenes/player.tscn").instantiate()
	player.global_position = startPos
	add_child(player)
	
func craft(item1, item2):
	ingredients.append([item1, item2])
	if ingredients.size() == 2:
		var new_item = match_items()
		if new_item != null:
			spawn_crafted_item(new_item, item1.global_position)
			item1.queue_free()
			item2.queue_free()
			
func spawn_crafted_item(itemID : int, pos : Vector3):
	var item = load(itemPath + current_level + "/" + str(itemID) + itemFormat).instantiate()
	item.position = pos
	get_node(current_level).add_child(item)
	ingredients.clear()
		
func check_for_recipe(items : Array):
	for i in craftingRecipes:
		var recipe_ingredients : Array = [i[0], i[1]]
		if items[0].get_dropID() in recipe_ingredients and items[1].get_dropID() in recipe_ingredients:
			return i[2]
			
	return null
		
func match_items():
	var item1 : Array = ingredients[0]
	var item2 : Array = ingredients[1]
	
	if item1[0] == item2[1] and item1[1] == item2[0]:
		return check_for_recipe(item1)
	else:
		return null
	
