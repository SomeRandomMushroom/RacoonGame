extends CharacterBody2D

@onready var death_particle=preload('res://effects/burst/default_burst_particle.tscn')
@onready var projectile=preload("res://Entities/enemies/Onomato/onomato_projectile.tscn")
@onready var vis=$Visible
@onready var draw_layer=$Visible/DrawLayer
@onready var health=$Visible/DrawLayer/HatHealthbar
@onready var navigator=$NavigationAgent2D
@onready var animator=$AnimationTree
@export var weight=200
@export var MAXMOVESPEED=200
@export var ACCELERATION=5
@export var preferred_distance=300
@export var preferred_distance_left_bound=.9
@export var preferred_distance_right_bound=1.1

const FRICTION=3
const LAUNCHSPEED=500.0
const GRAVITY=.02

var weak=true
var grappled=false
var mouse_hovering=false
var launched=false
var delta=0
var current_target=position
var aggrevated=false
var z_pos=0
var z_vel=0
var in_air=false
var floating=true
var floating_tween=null
var state_machine=null
var attacking=false
var can_shoot=true
var projectile_speed=500

signal death

#TODO: on initialization, randomize preferred_distance and bounds; could set to export var
func _ready() -> void:
	state_machine=animator.get('parameters/playback')
	navigator.set_max_speed(MAXMOVESPEED*Global.DELTA_MODIFIER)
	health.connect('empty', die)
	float_up()


func _physics_process(og_delta: float) -> void:
	#TODO: fix this
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
			velocity=velocity.length()*(tangent+position.direction_to(gp)/30)
	elif not (launched or grappled or attacking):
		#do manual
		if aggrevated:
			animator.set('parameters/moving/blend_position', sign(Global.player.position.x-position.x))
			var dtot=navigator.distance_to_target()
			if dtot<preferred_distance*preferred_distance_right_bound:
				if dtot>preferred_distance*preferred_distance_left_bound:
					#perfect distance, friction
					velocity=velocity.move_toward(Vector2.ZERO, FRICTION*delta)
				else:
					#Too close
					velocity=velocity.move_toward(-position.direction_to(Global.player.position)*MAXMOVESPEED, ACCELERATION*delta)
			else:
				if dtot<preferred_distance*1.5 and not attacking and can_shoot:
					attacking=true
					state_machine.travel('attack')
					animator.set('parameters/attack/blend_position', sign(Global.player.position.x-position.x))
				else:
					velocity=velocity.move_toward(position.direction_to(current_target)*MAXMOVESPEED, ACCELERATION*delta)
	if not launched:
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


func end_attack_anim():
	attacking=false
	state_machine.travel('moving')


func shoot_projectile():
	AudioManager.create_2d_audio_at_location(position, SoundEffect.SOUND_EFFECT_TYPE.ONOMATOTRIPLESHOT)
	var p=projectile.instantiate()
	add_sibling(p)
	p.position=position
	p.velocity=position.direction_to(Global.player.position)*projectile_speed
	p=projectile.instantiate()
	add_sibling(p)
	p.position=position
	p.velocity=(position.direction_to(Global.player.position)+Vector2.from_angle(deg_to_rad(20))).normalized()*projectile_speed
	p=projectile.instantiate()
	add_sibling(p)
	p.position=position
	p.velocity=(position.direction_to(Global.player.position)+Vector2.from_angle(-deg_to_rad(20))).normalized()*projectile_speed
	can_shoot=false
	$CanAttack.wait_time=randf_range(1, 1.4)
	$CanAttack.start()


func float_up():
	if floating:
		if is_instance_valid(floating_tween):
			floating_tween.stop()
		floating_tween=create_tween()
		floating_tween.tween_property(draw_layer, 'position:y', -10, 1).set_trans(Tween.TRANS_CUBIC)
		floating_tween.tween_callback(float_down)
		floating_tween.play()
	else:
		draw_layer.position.y=0


func float_down():
	if floating:
		if is_instance_valid(floating_tween):
			floating_tween.stop()
		floating_tween=create_tween()
		floating_tween.tween_property(draw_layer, 'position:y', 10, 1).set_trans(Tween.TRANS_CUBIC)
		floating_tween.tween_callback(float_up)
		floating_tween.play()
	else:
		draw_layer.position.y=0


func stop_floating():
	floating=false
	draw_layer.position.y=0
	if is_instance_valid(floating_tween):
		floating_tween.stop()


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
	AudioManager.create_2d_audio_at_location(position, SoundEffect.SOUND_EFFECT_TYPE.ENEMYHIT1 if randi_range(1, 2)==2 else SoundEffect.SOUND_EFFECT_TYPE.ENEMYHIT2)
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
	if area.is_in_group('enemy') and area.get_parent()!=self:
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


func _on_can_attack_timeout() -> void:
	can_shoot=true
