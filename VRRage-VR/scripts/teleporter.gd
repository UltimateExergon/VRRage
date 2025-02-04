extends Node3D

@export var teleport_level : String
@export var label_text : String

@onready var main_node := get_tree().root.get_children()[2]

func _ready():
	$Label3D.text = "To: " + label_text

func _on_area_3d_body_entered(body):
	if body.is_in_group("PLAYER") and main_node.can_teleport == true:
		print("Player entered teleporter to: ", teleport_level, " at " , self.global_position)
		main_node.load_level(teleport_level)
		main_node.teleport_player()
		main_node.activate_teleport_timer()
