extends Node2D

var t=null

func _ready():
	scale=Vector2.ZERO

func expand():
	if is_instance_valid(t):
		t.stop()
	t=create_tween()
	t.tween_property(self, 'scale', Vector2.ONE*10, .2)
	t.play()

func deflate():
	if is_instance_valid(t):
		t.stop()
	t=create_tween()
	t.tween_property(self, 'scale', Vector2.ZERO, .15)
	t.play()
