extends AnimatedSprite2D
@export var not_real=true
func _ready():
	if not_real:
		var t=Timer.new()
		add_child(t)
		t.wait_time=.02
		t.start()
		t.connect('timeout', start_disapearing)
func start_disapearing():
	modulate=Color(1, 1, 1, .4)
	var tween=create_tween()
	tween.tween_property(self, 'modulate', Color(1, 1, 1, 0), .3)
	tween.tween_callback(queue_free)
func get_pos():
	return global_position
