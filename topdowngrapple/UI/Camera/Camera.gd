extends Camera2D

@onready var shake_timer=$ShakeTimer
@onready var window_scale=DisplayServer.screen_get_size().x/320 #test on different screens, may break

var locking=[false, Vector2.ZERO]
var shaking=false
var const_shaking=false
var shake_offset=Vector2.ZERO
var intensity=0
var const_int=0
var zoom_tween=null

signal zoom_finish

func _physics_process(_delta):
	if shaking:
		shake_offset=Vector2(randi_range(-intensity, intensity), randi_range(-intensity, intensity))
	elif const_shaking:
		shake_offset=Vector2(randi_range(-const_int, const_int), randi_range(-const_int, const_int))
	else:
		offset=Vector2.ZERO
	if locking[0]:
		position=lerp(position, locking[1], 5)
	offset=shake_offset+(get_viewport().get_mouse_position()*window_scale-Vector2(DisplayServer.screen_get_size()/2))/12


func change_zoom(percent: float, speed=.5):
	if is_instance_valid(zoom_tween):
		zoom_tween.stop()
	zoom_tween=create_tween()
	zoom_tween.tween_property(self, 'zoom', Vector2.ONE*percent, speed)
	zoom_tween.tween_callback(zoom_finish.emit)
	zoom_tween.play()
func chain_zoom(ps: Array):
	if is_instance_valid(zoom_tween):
		zoom_tween.stop()
	zoom_tween=create_tween()
	for x in ps:
		zoom_tween.tween_property(self, 'zoom', Vector2.ONE*x[0], x[1])
	zoom_tween.tween_callback(zoom_finish.emit)
	zoom_tween.play()

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
