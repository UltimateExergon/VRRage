extends XRToolsPickable

@onready var baseball_bat = self.get_parent().get_parent().find_child("baseball_bat").get_children()[0]

func _ready() -> void:
	baseball_bat.connect("ready", _on_baseball_bat_ready)
	
func _on_baseball_bat_ready():
	baseball_bat.enabled = false

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			on_predelete()

func on_predelete() -> void:
	baseball_bat.enabled = true
	print(baseball_bat.enabled)
