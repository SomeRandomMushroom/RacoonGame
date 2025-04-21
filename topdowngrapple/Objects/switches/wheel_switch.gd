extends Node2D

@onready var rotator=$scaler/rotator
@export var connected_obj=Node
@export var max_value=20
@export var two_way=false

var rotational_vel=0
var value=0


func _physics_process(_delta: float) -> void:
	rotator.rotate(rotational_vel)
	value+=rotational_vel*(sign(rotational_vel) if two_way else 1)
	rotational_vel=lerpf(rotational_vel, 0, .02)
	if abs(rotational_vel)<.001:
		rotational_vel=0
	value=clampf(value, 0, max_value)
	if connected_obj.owner!=get_tree():
		connected_obj.gradual_switch(value/max_value)

func set_rotational_force(f):
	rotational_vel=f
