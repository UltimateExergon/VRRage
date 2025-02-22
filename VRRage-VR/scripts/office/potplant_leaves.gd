extends Destruction

@export var particleAmount : int = 250
@export var particleEmitTime : float = 0.1

@onready var particleEmitter : GPUParticles3D = $LeafParticles

var emitTimer : Timer

func _ready():
	super()
	
	emitTimer = Timer.new()
	emitTimer.one_shot = true
	add_child(emitTimer)
	emitTimer.timeout.connect(_on_emitTimer_timeout)
	
	particleEmitter.emitting = false
	particleEmitter.amount = particleAmount

func destroy() -> void:
	self.get_children()[0].queue_free()
	
	particleEmitter.emitting = true
	emitTimer.start()
	
	add_floatingScore()
	add_score_points()
	
func _on_emitTimer_timeout():
	particleEmitter.emitting = false
