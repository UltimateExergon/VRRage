extends Destruction

func destroy() -> void:
	if can_destroy:
		soundPlayer.play()

		can_destroy = false
		main_node.add_active_shard(shard_container)
		
		var right_hand = get_node("/root/Main/Player/RightHand")
		var left_hand = get_node("/root/Main/Player/LeftHand")
		right_hand.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.5, 0.0)
		left_hand.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.5, 0.0)

		start_shards(Vector3.ZERO)
		self.get_child(0).visible = false

		add_drop(Vector3.ZERO)
		emit_Particles()
		add_floatingScore()
	
		add_score_points()

		await soundPlayer.finished
		
		self.get_child(0).queue_free()
		
