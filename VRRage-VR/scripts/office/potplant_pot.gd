extends Destruction

@onready var leaves = find_child("leaves")
@onready var leaves_body = leaves.get_children()[0]

func destroy() -> void:
	print("POTPLANT POT SCRIPT DESTROY CALLED; DESTROYING LEAVES")
	leaves.destroy()
	super()

func _on_potplant_potrigid_picked_up(_pickable):
	print("CHANGED LEAVERS LAYER/MASK TO PICKED UP")
	leaves_body.collision_layer = leaves_body.DEFAULT_LAYER
	leaves_body.collision_mask = leaves_body.DEFAULT_LAYER

func _on_potplant_potrigid_dropped(_pickable):
	print("CHANGED LEAVERS LAYER/MASK TO DROPPED")
	leaves_body.set_collision_mask_value(2, false)
	leaves_body.set_collision_mask_value(17, false)
	leaves_body.set_collision_layer_value(3, false)
	leaves_body.set_collision_layer_value(4, true)
	leaves_body.set_collision_layer_value(17, false)
