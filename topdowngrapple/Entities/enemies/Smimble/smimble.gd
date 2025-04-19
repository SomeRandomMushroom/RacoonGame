extends CharacterBody2D

@onready var death_particle=preload('res://effects/burst/default_burst_particle.tscn')
@onready var vis=$Visible
@onready var draw_layer=$Visible/DrawLayer
@onready var health=$Visible/DrawLayer/HatHealthbar
@onready var navigator=$NavigationAgent2D
@onready var animator=$AnimationTree
@onready var ray=$RayCast2D
@export var weight=200
@export var MAXMOVESPEED=100
@export var ACCELERATION=1.5
@export var preferred_distance=60
@export var preferred_distance_left_bound=.9
@export var preferred_distance_right_bound=1.1
@export var teleport_distance=1000

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
var floating=true
var floating_tween=null
var can_teleport=true
var state_machine=null
var teleporting=false

signal death

#TODO: on initialization, randomize preferred_distance and bounds; could set to export var
func _ready() -> void:
	state_machine=animator.get('parameters/playback')
	navigator.set_max_speed(MAXMOVESPEED*Global.DELTA_MODIFIER)
	health.connect('empty', die)
	float_up()


func _physics_process(og_delta: float) -> void:
	#TODO: fix this
	if teleporting:
		ray.position=Global.player.position-position
		ray.target_position=Global.player.velocity*.6
	else:
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
				animator.set('parameters/conditions/attacking', true)
				var dtot=navigator.distance_to_target()
				if dtot<preferred_distance*preferred_distance_right_bound:
					if dtot>preferred_distance*preferred_distance_left_bound:
						#perfect distance, friction
						velocity=velocity.move_toward(Vector2.ZERO, FRICTION*delta)
					else:
						#Too close
						velocity=velocity.move_toward(-position.direction_to(Global.player.position)*MAXMOVESPEED, ACCELERATION*delta)
				else:
					if can_teleport and dtot>teleport_distance:
						print("trying to teleport")
						can_teleport=false
						aggrevated=false
						$TeleportCooldown.wait_time=randi_range(8, 16)
						$TeleportCooldown.start()
						animator.set('parameters/conditions/attacking', false)
						state_machine.travel('teleport_close')
						teleporting=true
					else:
						#navigate to player
						velocity=velocity.move_toward(position.direction_to(current_target)*MAXMOVESPEED, ACCELERATION*delta)
			else:
				#friction
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


func teleport():
	animator.set('parameters/conditions/teleport', false)
	aggrevated=true
	if ray.is_colliding():
		position=ray.get_collision_point().move_toward(Global.player.position, 32)
	else:
		position=Global.player.position+Global.player.velocity*.6
	teleporting=false
	print("teleported to: "+str(position))


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


func _on_teleport_cooldown_timeout() -> void:
	can_teleport=true
