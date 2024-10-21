extends CPUParticles2D
@onready var particle2=preload('res://effects/dependant/speedparticle2.tscn')
func _ready():
	emitting=true
func _on_finished() -> void:
	queue_free()
