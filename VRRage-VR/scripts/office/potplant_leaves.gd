extends Destruction

@onready var rigid = self.get_child(0)
@onready var saved_transform = rigid.transform

var destroyed : bool = false

func destroy():
	if not destroyed:
		destroyed = true
		get_parent().get_parent().leaves_destroyed = true
	
		super()

func _physics_process(delta: float) -> void:
	if not destroyed:
		rigid.transform = saved_transform
