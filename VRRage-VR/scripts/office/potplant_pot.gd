extends Destruction

@onready var leaves = $RigidBody3D/leaves
@onready var leaves_body = leaves.get_node("potplant_leaves-rigid")
@onready var saved_position : Vector3 = self.position

func destroy() -> void:
	leaves.destroy()
	super()
	
func _physics_process(delta):
	if leaves_body.freeze == true:
		self.position = get_parent().get_parent().position + saved_position

func _on_potplant_potrigid_picked_up(pickable):
	leaves_body.freeze = true

func _on_potplant_potrigid_dropped(pickable):
	leaves_body.freeze = false
