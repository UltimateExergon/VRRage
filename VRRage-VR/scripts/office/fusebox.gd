extends Destruction

@onready var rigid = self.get_child(0)
@onready var saved_transform = rigid.transform

var destroyed : bool = false

func destroy():
	if not destroyed:
		print("FUSEBOX DESTROYED")
		destroyed = true
		
		for i in get_tree().get_nodes_in_group("ColorLight"):
			i.set_alert_color()
			
		for j in get_tree().get_nodes_in_group("Level"):
			j.set_alert_color()

		super()
	
func _physics_process(delta: float) -> void:
	if not destroyed:
		rigid.transform = saved_transform
