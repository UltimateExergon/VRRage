extends Destruction

func destroy() -> void:
	if can_destroy:
		soundPlayer.play()

		can_destroy = false
		main_node.add_active_shard(shard_container)

		start_shards(Vector3.ZERO)

		for i in self.get_child(0).get_children():
			if i is MeshInstance3D or i is CollisionShape3D or i is CollisionPolygon3D:
				i.visible = false

		add_drop(Vector3.ZERO)
		emit_Particles()
		add_floatingScore()
	
		add_score_points()

		await soundPlayer.finished
		
		self.get_child(0).queue_free()
		
