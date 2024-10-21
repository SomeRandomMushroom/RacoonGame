extends Node

const DELTA_MODIFIER=500

var pause_timer=null
var player
var paused=false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize()


func dir_from_speed(angle_to_normal, vel_angle):
	# calculates (angle from position to perpendicular of tangent)-(90 degrees)-(angle of velocity)
	var calc=abs(angle_to_normal-1.5708-vel_angle)
	if calc>PI:
		calc=2*PI-calc
	return calc<=1.5708 #90 degrees in radians

func set_pause_timer(timer):
	pause_timer=timer
	pause_timer.connect('timeout', resume)


func timed_pause(duration):
	if not paused:
		paused=true
		get_tree().set_pause(true)
		pause_timer.wait_time=duration
		pause_timer.start()


func resume():
	get_tree().set_pause(false)
	paused=false
