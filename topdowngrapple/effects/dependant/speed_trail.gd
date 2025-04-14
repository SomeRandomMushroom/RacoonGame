extends Line2D
var max_delay=40
var delay=0
func _process(delta: float) -> void:
	delay-=1
	if delay<=0 and points.size()>0:
		remove_point(0)
		delay=max_delay
		print('hi')
