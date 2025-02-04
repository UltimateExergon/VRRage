extends Node3D

@export var teleport_level : String
@export var label_text : String

@onready var main_node := get_tree().root.get_children()[3]

func _ready():
	$Label3D.text = "To: " + label_text

func _on_area_3d_body_entered(body):
	if body.is_in_group("PLAYER"):
		print("Player entered teleporter to: ", teleport_level)
		main_node.load_level(teleport_level)
		main_node.teleport_player()
