extends Node

const main_order : int = 3

const levelPath : String = "res://scenes/Level/"
const itemPath : String = "res://scenes/items/"
const recipePath : String = "res://craftingRecipes/"
const levelFormat : String = ".tscn"
const itemFormat : String = ".tscn"
const recipeFormat : String = ".csv"

@onready var outline_shader = preload("res://shader/outline.gdshader")
const outline_color : Color = Color8(255, 255, 255, 255)
const outline_width : float = 2.0
