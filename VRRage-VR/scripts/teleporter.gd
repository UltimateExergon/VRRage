extends Node3D

@export var teleport_level : String ##Scene Name of Level to teleport to
@export var label_text : String ##Text to be displayed as default_text

@onready var main_node := get_tree().root.get_children()[Globals.main_order]

func _ready():
	var level_highscore : int = Globals.get_highscore(teleport_level)
	
	$Label3D.text = label_text
	
	if teleport_level != "level_select":
		var highscore_text : String = "\nHighscore: " + str(level_highscore)
		$Label3D.text += highscore_text

func _on_area_3d_body_entered(body):
	if teleport_level == "exit":
		get_tree().quit()
	
	if body.is_in_group("PLAYER") and main_node.can_teleport == true:
		print("Player entered teleporter to: ", teleport_level, " at " , self.global_position)
		main_node.load_level(teleport_level)
