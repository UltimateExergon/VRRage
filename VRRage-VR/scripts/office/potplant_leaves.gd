extends Destruction

@export var particleAmount : int = 250

@onready var particleEmitter : GPUParticles3D = $LeafParticles

func destroy() -> void:
	particleEmitter.amount = particleAmount
	particleEmitter.one_shot = true
	
	add_floatingScore()
	add_score_points()
