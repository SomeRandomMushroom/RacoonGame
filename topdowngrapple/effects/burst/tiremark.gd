extends Line2D

var legnth=0
var width_curve_points=[]

func update_width():
	pass
func release():
	$Timer.start()
func _on_timer_timeout() -> void:
	var tween=create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1)
	tween.tween_callback(queue_free)
