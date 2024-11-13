extends Node

const DELTA_MODIFIER=500
const rad_90=deg_to_rad(90)

var pause_timer=null
var player
var paused=false
var hit_paused=false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize()


func dir_from_speed(angle_to_normal, vel_angle):
	# calculates (angle from position to perpendicular of tangent)-(90 degrees)-(angle of velocity)
	var calc=abs(angle_to_normal-rad_90-vel_angle)
	calc=loop_pi(calc)
	return calc<=rad_90

func loop_pi(n):
	return 2*PI-n if n>PI else n


func game_pause():
	if not hit_paused:
		get_tree().set_pause(true)
	paused=true
	pause_timer.process_mode=PROCESS_MODE_PAUSABLE


func game_unpause():
	if not hit_paused:
		get_tree().set_pause(true)
	paused=false
	pause_timer.process_mode=PROCESS_MODE_WHEN_PAUSED


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
