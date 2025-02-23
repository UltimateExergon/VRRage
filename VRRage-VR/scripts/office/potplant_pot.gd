extends Destruction

@onready var leaves = $RigidBody3D/leaves

func destroy() -> void:
	leaves.destroy()
	super()
