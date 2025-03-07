extends StaticBody3D

const normal_color : Color = Color8(255, 255, 255, 120)
const alert_color : Color = Color8(158, 26, 26, 255)

@onready var light = $SpotLight3D

func _ready():
	light.light_color = normal_color

func set_alert_color():
	light.light_color = alert_color
