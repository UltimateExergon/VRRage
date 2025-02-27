extends Destruction

@onready var leaves = find_child("leaves")

func destroy() -> void:
	leaves.destroy()
	super()

func _on_potplant_potrigid_picked_up(pickable):
	leaves.get_children()[0].set_collision_mask_value(1, false)
	leaves.get_children()[0].set_collision_mask_value(3, false)
	leaves.get_children()[0].set_collision_mask_value(4, false)
	leaves.get_children()[0].set_collision_layer_value(1, false)

func _on_potplant_potrigid_dropped(pickable):
	leaves.get_children()[0].set_collision_mask_value(1, true)
	leaves.get_children()[0].set_collision_mask_value(3, true)
	leaves.get_children()[0].set_collision_mask_value(4, true)
	leaves.get_children()[0].set_collision_layer_value(1, true)
