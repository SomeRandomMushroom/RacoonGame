extends AnimatableBody2D

const LAUNCHSPEED=500

var attatch_point=Vector2.ZERO
var velocity=Vector2.ZERO
var friction=1
var grappled=false

func _physics_process(delta: float) -> void:
	if grappled:
		set_collision_mask_value(3, false)
		var gp=Global.player.position
		if gp.distance_to(position)<gp.distance_to(position+velocity*delta):
			var tangent=position-gp
			tangent=-Vector2(tangent.y, tangent.x).normalized()
			if Global.dir_from_speed(position.angle_to_point(gp), velocity.angle()):
				tangent.y*=-1
			else:
				tangent.x*=-1
			velocity=velocity.length()*tangent
	velocity=velocity.move_toward(Vector2.ZERO, friction*delta*Global.DELTA_MODIFIER)
	move_and_collide(velocity*delta)



func get_grappled():
	grappled=true


func is_fast():
	return velocity.length()>=LAUNCHSPEED


func damage_calc():
	return floor(velocity.length()/LAUNCHSPEED/5)


func release():
	grappled=false
	if velocity.length()>LAUNCHSPEED:
		set_collision_mask_value(3, false)
	set_collision_mask_value(3, true)
