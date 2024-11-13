extends CharacterBody2D

@onready var speed_particle=preload('res://effects/dependant/speed_particle.tscn')
@onready var grappler_obj=preload('res://Entities/tools/grappler/grapple_hook.tscn')
@onready var line=$Line2D
@onready var remote=$Remote
@onready var camera=$DrawLayer/Camera2D
@onready var squash=$DrawLayer/Squash
@onready var ui=$UI
@onready var animator=$Lincoln
@onready var tailpoint=$DrawLayer/TailPoint
@onready var tailline=$DrawLayer/Tail
@onready var tail=load('res://Entities/Player/tail.tscn')

const speed_mod=.65
const MAXSPEED=1600
const MAXMOVESPEED=80.0*speed_mod
const ATTACKINGSPEED=800.0*speed_mod
const FRICTION=3*speed_mod
const SPEEDFRICTION=1*speed_mod
const MAXBOOSTSPEED=1200.0*speed_mod
const WALLJUMPSPEED=400.0*speed_mod
const INPUTTURNLENIENCY=deg_to_rad(30)
const PULLSPEED=1000.0*speed_mod
const JUMPDELAY=15
const STYLEFRAMES=10
const STYLESPEED=15.0*speed_mod
const GRAVITY=.02
const WALLRIDEFRAMES=30
const MAXFOCUSTIME=15
const SLIDEANGLE=deg_to_rad(25)
const GRAPPLEDIRCHANGEANGLE=deg_to_rad(40)

var aiming_to=Vector2.ZERO
var in_air=false
var is_air_action=false
var y_offset=0
var vertical_velocity=0
var throwspeed=10
var acceleration=20*speed_mod
var grappler=null
var jump_buffer=0
var style_jump_frames=0
var style_jump_cooldown=0
var last_step_pos=Vector2.ZERO
var wall_riding=false
var wall_ride_dir=Vector2.ZERO
var focusing=false
var focus_time=0
var prev_vel_speed=0
#var wall_ride_buffer=0
var delta

enum States {
	IDLE,
	MOVING,
	GRAPPLING,
	STYLING,
	FALLING,
}
var state=States.MOVING

signal death


func _ready() -> void:
	Global.player=self
	squash.maxim=MAXSPEED
	ui.connect('death', die)
	tail=tail.instantiate()
	get_parent().connect('ready', set_tail)
func set_tail():
	add_sibling(tail)
	tailpoint.remote_path=tail.begin.get_path()
func edit_tail_line(index:int, pos:Vector2):
	tailline.points[index]=pos-$DrawLayer.position-position


func _physics_process(og_delta: float) -> void:
	delta=og_delta*Global.DELTA_MODIFIER
	var input=Input.get_vector('left', 'right', 'up', 'down')

	general_inputs()
	movement(input, og_delta)
	velocity=velocity.clampf(-MAXSPEED, MAXSPEED)
	slide(input, velocity, move_and_slide())
	jumping(input)
	tick_timers()

	match state:
		States.IDLE:
			pass
		States.MOVING:
			if velocity:
				animator.set('parameters/Blend_Move/blend_position', velocity.normalized())
		States.GRAPPLING:
			pass
		States.FALLING:
			pass


func movement(input, og_delta):
	squash.continuous_deform(velocity)
	#Movement Handler
	if wall_riding:
		pass
	else:
		if velocity.length()<=MAXMOVESPEED*delta:
			camera.const_shaking=false
			#squash.scale=lerp(squash.scale, Vector2.ONE, .2)
			#squash.skew=lerpf(squash.skew, 0, .2)
			if in_air:
				if input and not is_air_action:
					velocity+=input*acceleration*delta/20
			else:
				if input:
					if velocity.length()<=ATTACKINGSPEED*delta:
						velocity=lerp(velocity, input*MAXMOVESPEED*delta, acceleration/MAXMOVESPEED)
				velocity=velocity.move_toward(Vector2.ZERO, FRICTION*delta)
		else:
			if abs(MAXSPEED-velocity.length())<500:
				camera.const_shaking=true
				camera.const_int=2
			else:
				camera.const_shaking=false
			if input:
				velocity+=input*acceleration*delta/15
			if grappler:
				velocity=velocity.move_toward(Vector2.ZERO, SPEEDFRICTION*delta/5)
			else:
				velocity=velocity.move_toward(Vector2.ZERO, SPEEDFRICTION*delta)
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
				velocity=position.direction_to(gp)*max(PULLSPEED, velocity.length()*.8)
				squash.burst_deform(velocity.normalized())
			#If player is moving away from grappler
			elif gp.distance_to(position)<gp.distance_to(position+velocity*og_delta):
				var tangent=position-gp
				tangent=-Vector2(tangent.y, tangent.x).normalized()
				var calc=Global.loop_pi(abs(position.angle_to_point(gp)-Global.rad_90-velocity.angle()))
				if input and abs(calc-Global.rad_90)<GRAPPLEDIRCHANGEANGLE:
					calc+=(velocity.angle()-input.angle())
					calc=Global.loop_pi(abs(calc))
				if calc<=Global.rad_90:
					tangent.y*=-1
				else:
					tangent.x*=-1
				velocity=velocity.length()*tangent
				if grappler.attatched_type==grappler.entity and grappler.attatched_to.weakened:
					grappler.attatched_to.velocity+=-velocity/20


func jumping(input):
	#wall jumping
	if jump_buffer>0 and wall_riding:
		var collision=get_last_slide_collision()
		wall_riding=false
		velocity+=collision.get_normal()*WALLJUMPSPEED
		if abs(input.angle()-velocity.angle())<60:
			velocity+=input.normalized()*(WALLJUMPSPEED/2)

	#inair
	if in_air:
		if y_offset>=0:
			if style_jump_cooldown==-1:
				style_jump_cooldown=0
			y_offset=0
			in_air=false
			is_air_action=false
			state=States.MOVING
		$DrawLayer.position.y=y_offset
		y_offset+=vertical_velocity
		if not is_air_action:
			vertical_velocity+=GRAVITY*delta


func slide(input, prev_vel, collided):
	#Slide
	if collided:
		var collision=get_last_slide_collision()
		var g=collision.get_collider().get_groups()
		if 'wall' in g and 'bouncy' not in g:
			if not wall_riding and not in_air and prev_vel.length()>=ATTACKINGSPEED:#Input.get_action_strength('wall_ride') and prev_vel.length()>=ATTACKINGSPEED:
				wall_riding=true
				if grappler!=null:
					grappler.destroy()
				velocity=collision.get_normal()
				var influenced_angle=prev_vel.angle()+(prev_vel.angle_to(input)*input.length())
				var calc=abs(velocity.angle()+influenced_angle)
				if calc>PI:
					calc=2*PI-calc
				if calc>SLIDEANGLE:
					if Global.dir_from_speed(velocity.angle(), influenced_angle):
						velocity.x*=-1
					else:
						velocity.y*=-1
					velocity=Vector2(velocity.y, velocity.x)*prev_vel.length()
		else:
			wall_riding=false
	else:
		wall_riding=false


func tick_timers():
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
	if velocity.length()>=ATTACKINGSPEED and position.distance_to(last_step_pos)>=50:
		var p=speed_particle.instantiate()
		add_sibling(p)
		p.position=position
		p.direction=-velocity.normalized()
		p.initial_velocity_min=velocity.length()/4
		p.initial_velocity_max=velocity.length()/2
		last_step_pos=position


func general_inputs():
	#Jumps
	if Input.is_action_just_pressed('jump') and grappler==null and not in_air:
		if style_jump_frames>0:
			style_jump()
		else:
			jump_buffer=JUMPDELAY
	if velocity.length()<ATTACKINGSPEED:
		wall_riding=false
	if Input.is_action_just_pressed('focus'):
		Engine.time_scale=.2
		focusing=true
	elif Input.is_action_just_released('focus') or ui.energy<=0:
		Engine.time_scale=1
		focusing=false
	if Input.get_action_strength('brake') and velocity.length()>=MAXMOVESPEED:
		velocity=velocity.move_toward(Vector2.ZERO, FRICTION*2*delta)


func style_jump():
	if style_jump_cooldown==0:
		wall_riding=false
		style_jump_cooldown=-1
		style_jump_frames=0
		in_air=true
		vertical_velocity=-6.5
		y_offset=vertical_velocity-12
		prev_vel_speed=velocity.length()
		velocity=velocity.normalized()*(STYLESPEED*delta+velocity.length()*.1)


func air_grapple(target_obj):
	if in_air:
		style_jump_cooldown=25
		is_air_action=true
		velocity=position.direction_to(target_obj.position)*max(PULLSPEED, prev_vel_speed)
		vertical_velocity=-y_offset*((max(PULLSPEED, prev_vel_speed)/position.distance_to(target_obj.position))/60)


func empty_grappler():
	grappler=null
	line.points[1]=Vector2.ZERO


func squash_and_stretch():
	var min_s=.5
	var max_s=2-min_s
	var ratio=velocity.length()/MAXSPEED
	var n=velocity.normalized()
	squash.scale=lerp(squash.scale, ((max_s-min_s)*ratio+max_s)*n, .2)
	squash.skew=lerp(squash.skew, -velocity.angle(), .2)


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
		p.damage(floor(velocity.length()/ATTACKINGSPEED))
		camera.shake(4, .2)
		Global.timed_pause(.03)
		if jump_buffer>0:
			jump_buffer=0
			style_jump()
		else:
			style_jump_frames=STYLEFRAMES


func _on_hitbox_area_entered(area: Area2D) -> void:
	if 'enemy' in area.get_groups():
		ui.damage()
