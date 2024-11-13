extends Area2D

@onready var raycast=$RayCast2D

var velocity:=Vector2.ZERO
var attatched_to=null
var predicted_collision:=Vector2.ZERO
var distance:=150

enum {
	nothing,
	wall,
	entity
}
var attatched_type:=nothing

signal destroyed


func setup():
	rotation=velocity.angle()


func _physics_process(delta: float) -> void:
	match attatched_type:
		nothing:
			delta*=Global.DELTA_MODIFIER
			raycast.target_position.x=velocity.length()*2*delta
			position+=velocity*delta
			rotation=velocity.angle()
			if raycast.is_colliding():
				if 'wall' in raycast.get_collider().get_groups():
					if position.distance_to(position+velocity*delta)>=position.distance_to(raycast.get_collision_point()):
						attatched_type=wall
						attatched_to=raycast.get_collision_point()
						position=attatched_to
				elif 'enemy' in raycast.get_collider().get_groups():
					if position.distance_to(position+velocity*delta)>=position.distance_to(raycast.get_collision_point()):
						attatched_type=entity
						attatched_to=raycast.get_collider().get_parent()
						attatched_to.get_grappled()
						attatched_to.connect('death', destroy)
		entity:
			position=attatched_to.position


func destroy():
	emit_signal('destroyed')
	if attatched_type==entity:
		attatched_to.release()
	queue_free()
