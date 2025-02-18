extends "res://scripts/level.gd"

const normal_background_color : Color = Color8(137, 137, 137, 255)
const alert_background_color : Color = Color8(54, 54, 54, 255)

@onready var world_enironment : WorldEnvironment = $WorldEnvironment.environment

func _ready():
	super()
	
	world_enironment.set_bg_color(normal_background_color)

func set_alert_color():
	print("CHANGING LIGHT COLORS")
	world_enironment.set_bg_color(alert_background_color)
	
