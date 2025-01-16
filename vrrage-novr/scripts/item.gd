extends RigidBody3D

func _ready():
	self.body_entered.connect(_on_body_entered)
	
func _on_body_entered():
	pass
