extends CharacterBody2D

@onready var death_particle=preload('res://effects/burst/default_burst_particle.tscn')
@onready var vis=$Visible

@onready var draw_layer=$Visible/DrawLayer
@onready var health=$Visible/DrawLayer/HatHealthbar
@onready var navigator=$NavigationAgent2D
@onready var animator=$AnimationTree
@export var weight=400
@export var MAXMOVESPEED=800
@export var ACCELERATION=1.5

const FRICTION=3
const LAUNCHSPEED=500.0
const GRAVITY=.02

var weak=true
var grappled=false
var mouse_hovering=false
var launched=false
var delta=0
var current_target=position
var aggrevated=true
var z_pos=0
var z_vel=0
var in_air=false
var stored_dir=Vector2.ZERO

enum{
	APPROACH,
	RANDOM,
	ATTACK
}

var intention=RANDOM

signal death

#TODO: on initialization, randomize preferred_distance and bounds; could set to export var
func _ready() -> void:
	navigator.set_max_speed(MAXMOVESPEED*Global.DELTA_MODIFIER)
	health.connect('empty', die)


func _physics_process(og_delta: float) -> void:
	current_target=navigator.get_next_path_position()
	delta=og_delta*Global.DELTA_MODIFIER
	if grappled and weak:
		set_collision_mask_value(3, false)
		var gp=Global.player.position
		if gp.distance_to(position)<gp.distance_to(position+velocity*og_delta):
			var tangent=position-gp
			tangent=-Vector2(tangent.y, tangent.x).normalized()
			if Global.dir_from_speed(position.angle_to_point(gp), velocity.angle()):
				tangent.y*=-1
			else:
				tangent.x*=-1
			velocity=velocity.length()*tangent
	elif not (launched or grappled):
		#do manual
		if aggrevated:
			var dtot=navigator.distance_to_target()
			if dtot<150 or position.distance_to(Global.player.position+(Global.player.velocity*10))<200:
				intention=ATTACK
			else:
				intention=APPROACH
	velocity=velocity.move_toward(Vector2.ZERO, FRICTION*delta)
	move_and_slide()


	if in_air:
		if z_pos>=0:
			z_pos=0
			z_vel=0
			in_air=false
		z_pos+=z_vel*delta/5
		draw_layer.position.y=z_pos
		z_vel+=GRAVITY*delta



func animate_lunge(direction: Vector2):
	stored_dir=direction
	animator.set('parameters/Lunge/blend_position', direction)
	animator.set('parameters/conditions/lunging', true)


func lunge():
	velocity=stored_dir*MAXMOVESPEED
	animator.set('parameters/conditions/lunging', false)


func attack(direction: Vector2):
	animator.set('parameters/Attack/blend_position', direction)
	animator.set('parameters/conditions/attack', true)


func get_grappled():
	draw_layer.shake(15, .5)
	grappled=true


func release():
	grappled=false
	if velocity.length()>LAUNCHSPEED:
		launched=true
		#weak=false
		set_collision_mask_value(3, false)
		print('launched')
	set_collision_mask_value(3, true)


func damage(amount=1):
	print('enemy damaged: ', amount)
	draw_layer.shake(25, .5)
	var p=death_particle.instantiate()
	add_sibling(p)
	p.position=position
	health.current_health-=max(1, amount)
	health.update()


func die():
	death.emit()
	queue_free()


func _on_hitbox_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area.is_in_group('enemy'):
		if (grappled or launched) and velocity.length()>LAUNCHSPEED:
			area.get_parent().damage()
			damage(floor(velocity.length()/LAUNCHSPEED/50))
			launched=false
			set_collision_mask_value(3, true)
	elif area.is_in_group('object'):
		match area.get_meta('type'):
			'dumpster':
				var p=area.get_parent()
				if p.is_fast():
					damage(p.damage_calc())


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group('wall'):
		if (grappled or launched) and velocity.length()>LAUNCHSPEED:
			damage(floor(velocity.length()/LAUNCHSPEED/30))
		launched=false
		set_collision_mask_value(3, true)


func _on_navigation_update_timeout() -> void:
	if aggrevated:
		navigator.set_target_position(Global.player.position)


func _on_move_timer_timeout() -> void:
	print(intention)
	match intention:
		APPROACH:
			animate_lunge(position.direction_to(current_target))
		RANDOM:
			animate_lunge(Vector2(randf_range(-1, 1), randf_range(-1, 1)))
		ATTACK:
			attack(position.direction_to(Global.player.position))
