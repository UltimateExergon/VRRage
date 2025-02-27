extends Node

var highscores : Dictionary = {"birthday": 0, "markt": 0, "pub": 0, "office": 0, "testlevel": 0, "level_select": -1}

#Position of main node in get_tree().root.get_children()
const main_order : int = 3

const levelPath : String = "res://scenes/Level/"
const itemPath : String = "res://scenes/items/"
const recipePath : String = "res://craftingRecipes/"
const sceneFormat : String = ".tscn"
const recipeFormat : String = ".csv"

@onready var destructionScore = preload("res://scenes/destruction_score.tscn")

@onready var outline_shader = preload("res://shader/outline.gdshader")
const outline_color : Color = Color8(255, 255, 255, 50)
const outline_color_near : Color = Color8(91, 255, 92, 255)
const outline_color_crafting : Color = Color8(196, 195, 0, 150)
const outline_color_crafting_near : Color = Color8(196, 195, 0, 200)
const outline_color_none : Color = Color8(0, 0, 0, 0)
const outline_width : float = 2.0

func update_highscore(score : int, level : String) -> void:
	var current_highscore : int = highscores.get(level)
	if score > current_highscore:
		highscores[level] = score
		
func get_highscore(level : String) -> int:
	return highscores.get(level)
