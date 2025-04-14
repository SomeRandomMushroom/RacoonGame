extends Node

const DELTA_MODIFIER=500
const rad_90=deg_to_rad(90)

var pause_timer=null
var player
var current_level
var paused=false
var hit_paused=false


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize()


## calculates (angle from position to perpendicular of tangent)-(90 degrees)-(angle of velocity)
func dir_from_speed(angle_to_normal, vel_angle):
	var calc=abs(angle_to_normal-rad_90-vel_angle)
	calc=loop_pi(calc)
	return calc<=rad_90

##loops input n around pi
func loop_pi(n):
	return 2*PI-n if n>PI else n
func loop_all_pi(n):

	print('new')
	print(n)
	print(n-2*PI if n>PI else (n+2*PI if n<-PI else n))
	return n-2*PI if n>PI else (n+2*PI if n<-PI else n)


func circle_intersect(p1:Vector2, r1:float, p2:Vector2, r2:float, first:bool):
	var v=p1-p2
	var d=v.length()
	var u=v/d
	var xvec=p1+(d**2-r2**2+r1**2)*u/(2*d)
	var uperp=Vector2(u.y, -u.x)
	var c=(-d+r2-r1)*(-d-r2+r1)*(-d+r2+r1)*(d+r2+r1)
	var a = sign(c)*(abs(c)**0.5)/d
	return (xvec + a*uperp/2) if first else (xvec - a*uperp/2)

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
