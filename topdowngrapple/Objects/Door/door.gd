extends Node2D

@onready var door_l=$Door_left
@onready var door_r=$Door_right
@onready var open_pos_l=$Door_left/ColorRect.position.x
@onready var open_pos_r=$Door_right/ColorRect.size.x

var t=null


func gradual_switch(v):
	open_percentage(v)


func switch():
	open()


func open_percentage(percent):
	door_l.position.x=lerpf(0, open_pos_l, percent)
	door_r.position.x=lerpf(0, open_pos_r, percent)


func open():
	if is_instance_valid(t):
		t.stop()
	t=create_tween()
	t.set_parallel().tween_property(self, 'door_l/position::x', open_pos_l, 1)
	t.set_parallel().tween_property(self, 'door_r/position::x', open_pos_r, 1)
	t.play()


func close():
	if is_instance_valid(t):
		t.stop()
	t=create_tween()
	t.set_parallel().tween_property(self, 'door_l/position::x', 0, 1)
	t.set_parallel().tween_property(self, 'door_r/position::x', 0, 1)
	t.play()
