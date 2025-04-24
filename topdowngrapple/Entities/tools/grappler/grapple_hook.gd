extends Area2D

@onready var raycast=$RayCast2D

var velocity:=Vector2.ZERO
var attatched_to=null
var predicted_collision:=Vector2.ZERO
var distance:=150
var break_vel=Vector2.ZERO
var break_rot_vel=0

enum {
	nothing,
	wall,
	entity,
	object,
	broken
}
var attatched_type:=nothing

signal destroyed

func _ready() -> void:
	modulate=Color(1, 1, 1, 0)
	var t=Timer.new()
	add_child(t)
	t.wait_time=.02
	t.start()
	t.connect('timeout', appear)


func appear():
	modulate=Color(1, 1, 1, 1)


func setup():
	rotation=velocity.angle()


func _physics_process(delta: float) -> void:
	match attatched_type:
		nothing:
			delta*=Global.DELTA_MODIFIER
			raycast.target_position.x=velocity.length()*2*delta
			position+=velocity*delta
			rotation=velocity.angle()
			if raycast.is_colliding()  and is_instance_valid(raycast.get_collider()):
				if position.distance_to(position+velocity*delta)>=position.distance_to(raycast.get_collision_point()):
					if raycast.get_collider().is_in_group('object'):
						AudioManager.create_2d_audio_at_location(raycast.get_collision_point(), SoundEffect.SOUND_EFFECT_TYPE.GRAPPLECLANK)
						attatched_type=object
						if raycast.get_collider().get_meta('type')=='dumpster':
							attatched_to=raycast.get_collider()
							attatched_to.attatch_point=position-attatched_to.position
							attatched_to.get_grappled()
						else:
							attatched_to=raycast.get_collider().get_parent()
					elif raycast.get_collider().is_in_group('wall'):
						AudioManager.create_2d_audio_at_location(raycast.get_collision_point(), SoundEffect.SOUND_EFFECT_TYPE.GRAPPLECLANK)
						attatched_type=wall
						attatched_to=raycast.get_collision_point()
						position=attatched_to
					elif raycast.get_collider().is_in_group('enemy'):
						AudioManager.create_2d_audio_at_location(raycast.get_collision_point(), SoundEffect.SOUND_EFFECT_TYPE.GRAPPLECLANK)
						attatched_type=entity
						attatched_to=raycast.get_collider().get_parent()
						print(attatched_to.name)
						attatched_to.get_grappled()
						attatched_to.connect('death', destroy)
					
		entity:
			position=attatched_to.global_position
		object:
			match attatched_to.get_meta('type'):
				'wheel_switch':
					position=attatched_to.position
				'dumpster':
					position=attatched_to.global_position+attatched_to.attatch_point
		broken:
			position+=break_vel
			rotate(break_rot_vel)
			break_vel.y+=.1


func destroy(vel=Vector2(randf_range(-5, 5), randf_range(-8, 2)), rot_vel=randf_range(-.2, .2), time=1):
	destroyed.emit()
	print(time)
	break_vel=vel
	break_rot_vel=rot_vel
	raycast.enabled=false
	$CollisionShape2D.set_deferred('disabled', true)
	if attatched_type==entity or (attatched_type==object and attatched_to.get_meta('type')=='dumpster'):
		attatched_to.release()
	attatched_type=broken
	var t=create_tween()
	t.tween_property(self, 'modulate', Color(1, 1, 1, 0), time)
	t.parallel().tween_property(self, 'scale', Vector2.ZERO, time)
	t.tween_callback(queue_free)
	t.play()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group('enemy') and area.is_in_group('hurtbox'):
		destroy(area.position.direction_to(position)*2)
