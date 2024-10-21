extends CharacterBody2D

@onready var death_particle=preload('res://effects/burst/default_burst_particle.tscn')
@onready var draw_layer=$DrawLayer
@onready var status=$Status
@export var MAXHEALTH=10.0

const FRICTION=3
const LAUNCHSPEED=150.0

var weakened=true
var grappled=false
var health=MAXHEALTH
var mouse_hovering=false
var launched=false
var delta=0

signal death


func _physics_process(og_delta: float) -> void:
	delta=og_delta*Global.DELTA_MODIFIER
	if grappled and weakened:
		var gp=Global.player.position
		if gp.distance_to(position)<gp.distance_to(position+velocity*og_delta):
			var tangent=position-gp
			tangent=-Vector2(tangent.y, tangent.x).normalized()
			if Global.dir_from_speed(position.angle_to_point(gp), velocity.angle()):
				tangent.y*=-1
			else:
				tangent.x*=-1
			velocity=velocity.length()*tangent
	if not launched:
		velocity=velocity.move_toward(Vector2.ZERO, FRICTION*delta)
	move_and_slide()


func get_grappled():
	draw_layer.shake(15, .5)
	grappled=true


func release():
	grappled=false
	if velocity.length()>LAUNCHSPEED*delta:
		launched=true
		weakened=false
		print('launched')


func update_health():
	status.get_child(1).size.x=44*(health/MAXHEALTH)


func damage(amount=1):
	print(amount)
	draw_layer.shake(25, .5)
	var p=death_particle.instantiate()
	add_sibling(p)
	p.position=position
	p.color=$DrawLayer/ColorRect.color
	health-=max(1, amount)
	update_health()
	if health<=0:
		emit_signal('death')
		queue_free()


func _on_hitbox_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if 'enemy' in area.get_groups():
		if (grappled or launched) and velocity.length()>=LAUNCHSPEED:
			area.get_parent().damage()
			damage(floor(velocity.length()/LAUNCHSPEED/5))
			launched=false


func _on_hitbox_body_entered(body: Node2D) -> void:
	if 'wall' in body.get_groups():
		if (grappled or launched) and velocity.length()>=LAUNCHSPEED:
			damage(floor(velocity.length()/LAUNCHSPEED/3))
		launched=false
