extends Camera2D

@onready var shake_timer=$ShakeTimer

var locking=[false, Vector2.ZERO]
var shaking=false
var zooming=[false, 0, 0]
var intensity=0


func _physics_process(_delta):
	if shaking:
		offset=Vector2(randi_range(-intensity, intensity), randi_range(-intensity, intensity))
	if zooming[0]:
		zoom=Vector2.ONE*lerp(zoom.x, zooming[1], zooming[2])
		if zoom.x==zooming[1]:
			zooming[0]=false
	if locking[0]:
		position=lerp(position, locking[1], 5)


func change_zoom(percent, speed=.01):
	zooming=[true, percent, speed]


func lock(pos):
	locking=[true, pos]


func shake(i, d):
	shaking=true
	intensity=i
	shake_timer.wait_time=d
	shake_timer.start()


func _on_shake_timer_timeout():
	offset=Vector2.ZERO
	shaking=false
