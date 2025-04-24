extends Area2D
var velocity=Vector2.ZERO
func _physics_process(delta: float) -> void:
	position+=velocity*delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('wall'):
		queue_free()


func _on_timer_timeout() -> void:
	queue_free()
