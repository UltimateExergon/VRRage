extends "res://scripts/level.gd"

const normal_background_color : Color = Color8(137, 137, 137, 255)
const alert_background_color : Color = Color8(54, 54, 54, 255)

@onready var world_environment : Environment = $WorldEnvironment.environment

func _ready():
	super()
	
	world_environment.set_bg_color(normal_background_color)

func set_alert_color():
	print("CHANGING LIGHT COLORS")
	world_environment.set_bg_color(alert_background_color)
	change_levelMusic()
	
func change_levelMusic():
	musicPlayer.stop()
	musicPlayer.stream = Globals.office_redlight_music
	musicPlayer.volume_db = Globals.MusicVolumeDB
	musicPlayer.play()
	
