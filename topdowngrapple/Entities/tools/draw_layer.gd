extends CanvasGroup

@onready var shaketimer=$ShakeTimer

var shaking=false
var intensity=0.0


func _physics_process(_delta: float) -> void:
	if shaking:
		position=lerp(position, Vector2(randi_range(-intensity, intensity), randi_range(-intensity, intensity)), .8)
		intensity=lerpf(intensity, 0, shaketimer.wait_time)
	elif position!=Vector2.ZERO:
		position=lerp(position, Vector2.ZERO, .5)


func shake(i, d):
	shaketimer.wait_time=d
	shaketimer.start()
	shaking=true
	intensity=i


func _on_shake_timer_timeout() -> void:
	shaking=false
