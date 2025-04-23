extends AnimatableBody2D

const LAUNCHSPEED=500

var attatch_point=Vector2.ZERO
var velocity=Vector2.ZERO
var friction=1
var grappled=false
var next_to_wall=false

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
	var collision=move_and_collide(velocity*delta)



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


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group('object') and area.get_meta('type')=='dumpster' and is_fast():
		print('hit')
		var p=area.get_parent()
		print(p.velocity, ' ', velocity)
		if p.velocity.length()<velocity.length():
			p.set_deferred('velocity', p.velocity+velocity)
			set_deferred('velocity', velocity*-.6)
			AudioManager.create_2d_audio_at_location(position, SoundEffect.SOUND_EFFECT_TYPE.GARBAGECRASH, .8)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group('wall'):
		if body.is_in_group('object'):
			if body.get_meta('type')=='glass':
				if is_fast():
					body.destroy()
		else:
			next_to_wall=true
			velocity*=-.6
			AudioManager.create_2d_audio_at_location(position, SoundEffect.SOUND_EFFECT_TYPE.GARBAGECRASH, .6)


func _on_hurtbox_body_exited(body: Node2D) -> void:
	if body.is_in_group('wall'):
		next_to_wall=false
