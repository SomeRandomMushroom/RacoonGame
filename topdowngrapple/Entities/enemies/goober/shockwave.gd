extends Area2D


func _physics_process(delta: float) -> void:
	scale*=1.05

func _on_timer_timeout() -> void:
	var t=create_tween()
	t.tween_property(self, 'modulate', Color(1, 1, 1, 0), .2)
	t.tween_callback(queue_free)
	t.play()
