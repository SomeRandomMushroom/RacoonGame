extends Node2D

@onready var begin=$TailBegin
@onready var between=[$TailMid1, $TailMid2, $TailEnd]
@onready var joints=[$PinJoint2D, $PinJoint2D2, $PinJoint2D3]

var resting_pos=[Vector2(-32, -24), Vector2(-36, -32), Vector2(-37, -38)]
var d_ang_lim=-10
var u_ang_lim=10
var current_dir=1

func _process(delta: float) -> void:
	Global.player.edit_tail_line(0, begin.position)

func _physics_process(delta: float):
	var pvel=Global.player.velocity
	begin.constant_linear_velocity=pvel
	var temp=deg_to_rad(pvel.angle())
	d_ang_lim=int(temp-5)
	u_ang_lim=int(temp+5)
	for x in range(len(between)):
		Global.player.edit_tail_line(x+1, between[x].position)
		if pvel.length()>500:
			between[x].apply_force(-pvel*delta*300*x)
	for x in joints:
		x.angular_limit_lower=d_ang_lim
		x.angular_limit_upper=u_ang_lim
