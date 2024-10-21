extends CharacterBody2D

@onready var speed_particle=preload('res://effects/dependant/speed_particle.tscn')
@onready var grappler_obj=preload('res://Entities/tools/grappler/grapple_hook.tscn')
@onready var line=$Line2D
@onready var wall_detectors=$WallDetectors.get_children()
@onready var remote=$Remote
@onready var camera=$DrawLayer/Camera2D
@onready var ui=$UI

const MAXMOVESPEED=80.0
const ATTACKINGSPEED=800.0
const FRICTION=3
const SPEEDFRICTION=1
const MAXBOOSTSPEED=1200.0
const WALLJUMPSPEED=80.0
const INPUTTURNLENIENCY=deg_to_rad(30)
const PULLSPEED=1400.0
const JUMPDELAY=10
const STYLEFRAMES=5
const STYLESPEED=15.0
const GRAVITY=.2
const WALLRIDEFRAMES=30
const MAXFOCUSTIME=15

var aiming_to=Vector2.ZERO
var in_air=false
var is_air_action=false
var y_offset=0
var vertical_velocity=0
var throwspeed=10
var acceleration=20
var grappler=null
var jump_buffer=0
var style_jump_frames=0
var style_jump_cooldown=0
var last_step_pos=Vector2.ZERO
var wall_riding=false
var wall_ride_dir=Vector2.ZERO
var focusing=false
var focus_time=0
#var wall_ride_buffer=0
var delta

signal death


func _ready() -> void:
	Global.player=self
	ui.connect('death', die)


func _physics_process(og_delta: float) -> void:
	delta=og_delta*Global.DELTA_MODIFIER
	var input=Input.get_vector('left', 'right', 'up', 'down')

	general_inputs(input, og_delta)

	#Movement Handler
	if wall_riding:
		pass
	else:
		if velocity.length()<=MAXMOVESPEED*delta:
			if in_air:
				if input and not is_air_action:
					velocity+=input*acceleration*delta/20
			else:
				if input:
					if velocity.length()<=ATTACKINGSPEED*delta:
						velocity=lerp(velocity, input*MAXMOVESPEED*delta, acceleration/MAXMOVESPEED)
				velocity=velocity.move_toward(Vector2.ZERO, FRICTION*delta)
		else:
			if input:
				velocity+=input*acceleration*delta/15
			if grappler:
				velocity=velocity.move_toward(Vector2.ZERO, SPEEDFRICTION*delta/5)
			else:
				velocity=velocity.move_toward(Vector2.ZERO, SPEEDFRICTION*delta)


	#wall jumping
	if jump_buffer>0:
		var jump_dir=Vector2(
			-int(wall_detectors[1].is_colliding())+int(wall_detectors[0].is_colliding()),
			-int(wall_detectors[3].is_colliding())+int(wall_detectors[2].is_colliding())
			).normalized()
		if jump_dir:
			wall_riding=false
			jump_buffer=0
			if jump_dir.x:
				velocity+=sign(jump_dir+Vector2(0, input.y)).normalized()*WALLJUMPSPEED*delta
			elif jump_dir.y:
				velocity+=sign(jump_dir+Vector2(input.x, 0)).normalized()*WALLJUMPSPEED*delta

	#inair
	if in_air:
		if y_offset>=0:
			if style_jump_cooldown==-1:
				style_jump_cooldown=0
			y_offset=0
			in_air=false
			is_air_action=false
		$DrawLayer.position.y=y_offset
		y_offset+=vertical_velocity
		if not is_air_action:
			vertical_velocity+=GRAVITY

	#Grappler Handler
	if grappler == null:
		if Input.is_action_just_pressed('grapple') and not in_air:
			wall_riding=false
			#wall_ride_buffer=0
			#Create a grappler object
			var g=grappler_obj.instantiate()
			add_sibling(g)
			g.position=position
			g.velocity=position.direction_to(aiming_to)*throwspeed
			g.call_deferred('setup')
			grappler=g
			g.connect('destroyed', empty_grappler)
	elif Input.is_action_just_released('grapple'):
		grappler.destroy()
	#Everything in else occurs when the grappler exists.
	else:
		var gp=grappler.position
		line.points[-1]=gp-position
		#If grappler has attatched
		if grappler.attatched_type!=grappler.nothing:
			if Input.is_action_just_pressed('grapple_pull'):
				grappler.destroy()
				velocity=position.direction_to(gp)*PULLSPEED
			#If player is moving away from grappler
			elif gp.distance_to(position)<gp.distance_to(position+velocity*og_delta):
				var tangent=position-gp
				tangent=-Vector2(tangent.y, tangent.x).normalized()
				if Global.dir_from_speed(position.angle_to_point(gp), velocity.angle()):
					tangent.y*=-1
				else:
					tangent.x*=-1
				velocity=velocity.length()*tangent
				if grappler.attatched_type==grappler.entity and grappler.attatched_to.weakened:
					grappler.attatched_to.velocity+=-velocity/20



	#if Input.is_action_just_pressed('wall_ride'):
	#	wall_ride_buffer=WALLRIDEFRAMES
	#short-frame timers
	if jump_buffer>0:
		jump_buffer-=1
	if style_jump_frames>0:
		style_jump_frames-=1
	if style_jump_cooldown>0:
		style_jump_cooldown-=1
	if focusing:
		if focus_time<=0:
			ui.decrease_energy(1)
			focus_time=MAXFOCUSTIME
	elif focus_time<=0:
		ui.decrease_energy(-.7)
		focus_time=MAXFOCUSTIME

	#if wall_ride_buffer>0:
	#	wall_ride_buffer-=1
	if velocity.length()>=ATTACKINGSPEED and position.distance_to(last_step_pos)>=50:
		var p=speed_particle.instantiate()
		add_sibling(p)
		p.position=position
		p.direction=-velocity.normalized()
		p.initial_velocity_min=velocity.length()/4
		p.initial_velocity_max=velocity.length()/2
		last_step_pos=position

	#Slide
	var prev_vel=velocity
	if move_and_slide():
		var collision=get_last_slide_collision()
		if 'wall' in collision.get_collider().get_groups():
			if not wall_riding and not in_air and Input.get_action_strength('wall_ride') and prev_vel.length()>=ATTACKINGSPEED:
				wall_riding=true
				if grappler!=null:
					grappler.destroy()
				velocity=collision.get_normal()
				if Global.dir_from_speed(velocity.angle(), prev_vel.angle()+(prev_vel.angle_to(input)*input.length())):
					velocity.x*=-1
				else:
					velocity.y*=-1
				velocity=Vector2(velocity.y, velocity.x)*prev_vel.length()
		else:
			wall_riding=false
	else:
		wall_riding=false



func general_inputs(input, delta):
	#Jumps
	if Input.is_action_just_pressed('jump') and grappler==null and not in_air:
		if style_jump_frames>0:
			style_jump()
		else:
			jump_buffer=JUMPDELAY
	if Input.is_action_just_released('wall_ride') or velocity.length()<ATTACKINGSPEED:
		wall_riding=false
	if Input.is_action_just_pressed('focus'):
		Engine.time_scale=.2
		focusing=true
	elif Input.is_action_just_released('focus') or ui.energy<=0:
		Engine.time_scale=1
		focusing=false
	if Input.get_action_strength('brake'):
		velocity=velocity.move_toward(Vector2.ZERO, FRICTION*delta)



func style_jump():
	if style_jump_cooldown==0:
		wall_riding=false
		style_jump_cooldown=-1
		style_jump_frames=0
		in_air=true
		vertical_velocity=-6.5
		y_offset=vertical_velocity-12
		velocity=velocity.normalized()*(STYLESPEED*delta+velocity.length()*.1)


func air_grapple(target_obj):
	if in_air:
		style_jump_cooldown=25
		is_air_action=true
		velocity=position.direction_to(target_obj.position)*PULLSPEED
		vertical_velocity=-y_offset*(((PULLSPEED)/position.distance_to(target_obj.position))/60)


func empty_grappler():
	grappler=null
	line.points[1]=Vector2.ZERO


func die():
	print('died')
	emit_signal('death')


func _on_obj_collider_area_entered(area: Area2D) -> void:
	if 'object' in area.get_groups():
		match area.get_meta('type'):
			"speed_boost":
				if (velocity*2).length()<MAXBOOSTSPEED:
					velocity*=2
				else:
					velocity=velocity.normalized()*MAXBOOSTSPEED


func _on_hurtbox_area_entered(area: Area2D) -> void:
	var groups=area.get_groups()
	if 'enemy' in groups and 'hitbox' in groups and velocity.length()>=ATTACKINGSPEED:
		var p=area.get_parent()
		p.damage()
		camera.shake(8, .1)
		Global.timed_pause(.01)
		if jump_buffer>0:
			jump_buffer=0
			style_jump()
		else:
			style_jump_frames=STYLEFRAMES


func _on_hitbox_area_entered(area: Area2D) -> void:
	if 'enemy' in area.get_groups():
		ui.damage()
