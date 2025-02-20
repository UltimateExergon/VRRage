extends Destruction

@export var particleAmount : int = 250

@onready var particleEmitter : GPUParticles3D = $LeafParticles

func destroy() -> void:
	particleEmitter.amount = particleAmount
	particleEmitter.one_shot = true
	
	self.get_children()[0].queue_free()
	particleEmitter.emitting = true
	
	add_floatingScore()
	add_score_points()
