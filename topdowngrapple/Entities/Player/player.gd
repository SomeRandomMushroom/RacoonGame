extends CharacterBody2D

@onready var speed_particle=preload('res://effects/dependant/speed_particle.tscn')
@onready var ground_particle=preload('res://effects/dependant/ground_particle.tscn')
@onready var speed_burst_particle=preload('res://effects/burst/player_burst_speed.tscn')
@onready var tire_mark_particle=preload('res://effects/burst/tiremark.tscn')
@onready var jump_success_particle=preload('res://effects/burst/jump_success_particle.tscn')
@onready var land_shockwave=preload('res://Entities/Player/land_shockwave.tscn')
@onready var grappler_obj=preload('res://Entities/tools/grappler/grapple_hook.tscn')
@onready var speed_trail_scene=preload('res://effects/dependant/speed_trail.tscn')
@onready var sprite_clones=preload('res://Entities/Player/player_sprites.tscn')
@onready var vis=$Visible
@onready var draw_layer=$Visible/DrawLayer
@onready var line=$Visible/GrappleLine
@onready var remote=$Remote
@onready var camera=$Visible/DrawLayer/Camera2D
@onready var squash=$Visible/DrawLayer/Squash
@onready var ui=$UI
@onready var animator=$Lincoln
@onready var tailpoint=$Visible/DrawLayer/TailPoint
@onready var tailline=$Visible/DrawLayer/Tail
@onready var rotator=$Visible/DrawLayer/RotatingFX
@onready var slidecast=$SlideCast
@onready var sprite=$Visible/DrawLayer/Squash/PlayerSprites
@onready var rippler=$UI/Rippler
@onready var slow_effect_circle=$UI/SlowEffectCircle
@onready var gpt=$GrappleTimer
@onready var wall_riding_sfx=$WallRidingSFX
@onready var riding_sfx=$RidingSFX
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
const JUMPSTRENGTH=-4.5
const STYLEFRAMES=10
const JUMPDAMPENSPEED=15.0*speed_mod
const GRAVITY=.025*speed_mod
const WALLRIDEFRAMES=30
const MAXFOCUSTIME=15
const SLIDEANGLE=deg_to_rad(25)
const GRAPPLEDIRCHANGEANGLE=deg_to_rad(40)
const min_squash=.5
const max_squash=2-min_squash

var state_machine=null
var aiming_to=Vector2.ZERO
var in_air=false
var is_air_action=false
var z_pos=0
var z_vel=0
var throwspeed=8
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
var current_tire_mark=null
var speed_trail=null
var marking=false
var just_defocused=false
var hitstun=0
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
	state_machine=animator.get('parameters/playback')
	Global.player=self
	squash.maxim=MAXSPEED
	ui.connect('death', die)
	tail=tail.instantiate()
	get_parent().connect('ready', set_tail)
func set_tail():
	add_sibling(tail)
	tailpoint.remote_path=tail.begin.get_path()
func edit_tail_line(index:int, pos:Vector2):
	tailline.points[index]=pos-draw_layer.position-vis.position-position


func _physics_process(og_delta: float) -> void:
	delta=og_delta*Global.DELTA_MODIFIER
	var input=Input.get_vector('left', 'right', 'up', 'down')

	general_inputs()
	speed_fx()
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
				animator.set('parameters/moving/blend_position', velocity.normalized())
				if not (wall_riding or in_air):
					if not riding_sfx.playing:
						riding_sfx.play()
			elif riding_sfx.playing:
				riding_sfx.stop()
				
		States.GRAPPLING:
			pass
		States.FALLING:
			pass


func _process(_d: float) -> void:
	pass

#Every frame {
func movement(input, og_delta):
	#Movement Handler
	if wall_riding:
		slidecast.enabled=true
	else:
		slidecast.enabled=false
		if velocity.length()<=MAXMOVESPEED*delta:
			camera.const_shaking=false
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
			gpt.start()
	elif Input.is_action_just_released('grapple'):
		if grappler.attatched_type==grappler.nothing:
			grappler.destroy(grappler.position.direction_to(position)*throwspeed*delta, 0, .1)# grappler.position.distance_to(position)/(throwspeed*delta))
		else:
			grappler.destroy()
	#Everything in else occurs when the grappler exists.
	else:
		if not (current_tire_mark!=null and is_instance_valid(current_tire_mark)):
			current_tire_mark=tire_mark_particle.instantiate()
			add_sibling(current_tire_mark)
			marking=true
		var gp=grappler.position
		line.points[-1]=gp-position
		#If grappler has attatched
		if grappler.attatched_type!=grappler.nothing:
			if Input.get_action_strength('grapple_pull'):
				grappler.destroy()
				if ui.energy>0:
					velocity=position.direction_to(gp)*max(PULLSPEED, velocity.length()*1.1)
					ui.decrease_energy(4)
				else:
					velocity=position.direction_to(gp)*max(PULLSPEED, velocity.length()*.5)
				squash.burst_deform(velocity.normalized())
				var p=speed_burst_particle.instantiate()
				add_sibling(p)
				p.angle_min=rad_to_deg(-velocity.angle())
				p.angle_max=p.angle_min
				p.direction=-velocity.normalized()
				p.position=position
			#If player is moving away from grappler
			elif gp.distance_to(position)<gp.distance_to(position+velocity*og_delta):
				var tangent=gp-position
				tangent=Vector2(tangent.y, tangent.x).normalized()
				var calc=Global.loop_pi(abs(position.angle_to_point(gp)-Global.rad_90-velocity.angle()))
				if input and abs(calc-Global.rad_90)<GRAPPLEDIRCHANGEANGLE:
					calc+=(velocity.angle()-input.angle())
					calc=Global.loop_pi(abs(calc))
				if calc<=Global.rad_90:
					tangent.y*=-1
					animator.set('parameters/grapple_c/blend_position', gp.direction_to(position))
					state_machine.travel('grapple_c')
				else:
					tangent.x*=-1
				velocity=velocity.length()*(tangent+position.direction_to(gp)/25).normalized()
				if grappler.attatched_type==grappler.entity and grappler.attatched_to.weak:
					grappler.attatched_to.velocity+=-velocity*(delta/grappler.attatched_to.weight)
				elif grappler.attatched_type==grappler.object:
					match grappler.attatched_to.get_meta('type'):
						'wheel_switch':
							grappler.attatched_to.set_rotational_force(-angle_difference(gp.angle_to_point(position+velocity*og_delta), gp.angle_to_point(position)))
						'dumpster':
							grappler.attatched_to.velocity+=-velocity*(delta/600)
func jumping(input):
	#wall jumping
	if jump_buffer>0 and wall_riding:
		var collision=get_last_slide_collision()
		wall_riding=false
		velocity+=collision.get_normal()*WALLJUMPSPEED
		if abs(input.angle()-velocity.angle())<60:
			velocity+=input.normalized()*(WALLJUMPSPEED/2)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PLAYERGRABWALL)

	#inair
	if in_air:
		state=States.FALLING
		if riding_sfx.playing:
			riding_sfx.stop()
		if z_pos>=0:
			state=States.MOVING
			if style_jump_cooldown==-1:
				style_jump_cooldown=0
			z_pos=0
			in_air=false
			is_air_action=false
			state=States.MOVING
			#TODO: make sure this works
			if z_vel>6 and velocity.length()>ATTACKINGSPEED*1.2:
				var land=land_shockwave.instantiate()
				add_sibling(land)
				land.position=position
				land.size=velocity.length()/ATTACKINGSPEED*1.2
				camera.shake(8, .3)
			z_vel=0
			state_machine.travel('moving')
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PLAYERLAND1 if randi_range(1, 2)==2 else SoundEffect.SOUND_EFFECT_TYPE.PLAYERLAND2)
		z_pos+=z_vel*delta/5
		draw_layer.position.y=z_pos

		if not is_air_action:
			z_vel+=GRAVITY*delta
	else:
		z_pos=0
		draw_layer.position.y=0

func slide(input, prev_vel, collided):
	#Slide
	if collided:
		var collision=get_last_slide_collision()
		var g=collision.get_collider().get_groups()
		if 'wall' in g and 'bouncy' not in g:
			if not in_air and prev_vel.length()>=ATTACKINGSPEED:
				if wall_riding and slidecast.is_colliding():
					velocity=collision.get_normal()
					if slidecast.is_colliding():
						slidecast.rotate(Global.rad_90)
						slidecast.force_raycast_update()
						if slidecast.is_colliding():
							velocity.y*=-1
						else:
							velocity.x*=-1
					velocity=Vector2(velocity.y, velocity.x)*prev_vel.length()
					AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PLAYERGRABWALL)
					riding_sfx.stop()
					wall_riding_sfx.play()
				elif not wall_riding:
					wall_riding=true
					if grappler!=null:
						grappler.destroy()
					velocity=collision.get_normal()
					var ang=prev_vel.angle()#+(prev_vel.angle_to(input)*input.length())
					var calc=Global.loop_pi(abs(velocity.angle()+ang))
					if calc>SLIDEANGLE:
						if Global.dir_from_speed(velocity.angle(), ang):
							velocity.x*=-1
						else:
							velocity.y*=-1
						velocity=Vector2(velocity.y, velocity.x)*prev_vel.length()
					else:
						var influenced_angle=ang+(prev_vel.angle_to(input)*input.length())
						calc=Global.loop_pi(abs(velocity.angle()+influenced_angle))
						if calc>SLIDEANGLE:
							if Global.dir_from_speed(velocity.angle(), influenced_angle):
								velocity.x*=-1
							else:
								velocity.y*=-1
							velocity=Vector2(velocity.y, velocity.x)*prev_vel.length()
						else:
							ui.damage(1)
							camera.shake(floor(prev_vel.length()/ATTACKINGSPEED)*3, .2)
					AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PLAYERGRABWALL)
					riding_sfx.stop()
					wall_riding_sfx.play()
					
		else:
			wall_riding=false
	else:
		wall_riding=false
	slidecast.rotation=velocity.angle()


func speed_fx():
	squash.continuous_deform(velocity)
	if wall_riding:
		slidecast.enabled=true
	else:
		slidecast.enabled=false
		wall_riding_sfx.playing=false
	if velocity.length()<=MAXMOVESPEED*delta:
		camera.const_shaking=false
	if abs(MAXSPEED-velocity.length())<500 and !camera.const_shaking:
		camera.const_shaking=true
		camera.const_int=2
	elif camera.const_shaking:
		camera.const_shaking=false


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
	if hitstun>0:
		hitstun-=1
	if focusing:
		ui.decrease_energy(.02)
	else:
		ui.decrease_energy(-.005*max(MAXMOVESPEED*2, velocity.length())/ATTACKINGSPEED)

	if position.distance_to(last_step_pos)>=50:
		#every couple of steps
		#TODO: custom ground particle, adjusting for different textures
		last_step_pos=position

		if velocity.length()>=ATTACKINGSPEED:
			#always when speed
			#TODO: custom run particle/dust
			var p=ground_particle.instantiate()
			add_sibling(p)
			p.position=position
			p.direction=-velocity.normalized()
			p.initial_velocity_min=velocity.length()/4
			p.initial_velocity_max=velocity.length()/2
			if wall_riding:
				#only when wall riding
				p=speed_particle.instantiate()
				add_sibling(p)
				p.position=position
				p.direction=-velocity.normalized()
				p.initial_velocity_min=velocity.length()/4
				p.initial_velocity_max=velocity.length()/2
			elif marking:
				current_tire_mark.add_point(position)
			if focusing:
				speed_trail.add_point(sprite.global_position-Vector2(0, z_pos/2.0))
				print(sprite.position, ' ', sprite.global_position, position, z_pos)
			if velocity.length()>ATTACKINGSPEED*2.5:
				p=sprite_clones.instantiate()
				add_sibling(p)
				p.position=sprite.global_position-Vector2(0, z_pos/2.0)
				p.animation=sprite.animation
				p.frame=sprite.frame
				p.modulate=Color(1, 1, 1, 0)


func general_inputs():
	#Jumps
	if Input.is_action_just_pressed('jump') and ((grappler==null and not in_air) or (in_air and style_jump_frames>0)):
		if style_jump_frames>0:
			if in_air:
				style_jump(1)
			else:
				style_jump(.1)
		else:
			jump_buffer=JUMPDELAY
	if velocity.length()<ATTACKINGSPEED:
		wall_riding=false
	if Input.is_action_just_pressed('focus') and ui.energy>0:
		ripple_effect()
		slow_effect_circle.expand()
		Engine.time_scale=.2
		focusing=true
		just_defocused=false
		camera.change_zoom(.23, .02)
		if speed_trail==null:
			speed_trail=speed_trail_scene.instantiate()
			add_sibling(speed_trail)
	elif (Input.is_action_just_released('focus') or ui.energy<=0) and not just_defocused:
		slow_effect_circle.deflate()
		Engine.time_scale=1
		focusing=false
		just_defocused=true
		camera.change_zoom(.2, .08)
		if speed_trail!=null:
			speed_trail.release()
			speed_trail=null
	if Input.get_action_strength('brake') and velocity.length()>=MAXMOVESPEED:
		velocity=velocity.move_toward(Vector2.ZERO, FRICTION*2*delta)
# }


func ripple_effect():
	var tween=create_tween()
	rippler.material.set('shader_parameter/time_offset', Time.get_ticks_msec()*delta)
	print(rippler.material.get('shader_parameter/time_offset'), ', ')
	rippler.material.set('shader_parameter/speed', 4)
	rippler.material.set('shader_parameter/height', .038)
	tween.tween_property(rippler.material, 'shader_parameter/speed', 0, .08)
	tween.parallel().tween_property(rippler.material, 'shader_parameter/height', 0, .08)
	tween.play()
	#var t=get_tree().create_timer(.1133, true)
	#t.connect('timeout', rippler_off)
	#rippler.material.set('shader_parameter/on', true)


func rippler_off():
	rippler.material.set('shader_parameter/on', false)


func style_jump(speed):
	if style_jump_cooldown==0:
		var p=jump_success_particle.instantiate()
		add_sibling(p)
		p.position=position
		wall_riding=false
		style_jump_cooldown=-1
		style_jump_frames=0
		in_air=true
		z_vel=JUMPSTRENGTH
		z_pos=z_vel-12
		prev_vel_speed=velocity.length()
		velocity=velocity.normalized()*(JUMPDAMPENSPEED*delta+velocity.length()*speed)
		state_machine.travel('spin_basic')
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PLAYERJUMP1 if randi_range(1, 2)==2 else SoundEffect.SOUND_EFFECT_TYPE.PLAYERJUMP2)


func air_grapple(target_obj):
	if in_air:
		style_jump_cooldown=25
		is_air_action=true
		velocity=position.direction_to(target_obj.position)*max(PULLSPEED, prev_vel_speed)
		z_vel=-z_pos*((max(PULLSPEED, prev_vel_speed)/position.distance_to(target_obj.position))/60)


func off_ramp():
	if jump_buffer>0:
			jump_buffer=0
			style_jump(1)
	else:
		style_jump_frames=STYLEFRAMES

#hi there buddy
func empty_grappler():
	state_machine.travel('moving')
	set_grapple_line_origin(Vector2.ZERO)
	gpt.stop()
	grappler=null
	if marking:
		current_tire_mark.release()
		current_tire_mark=null
		marking=false
	line.points[1]=Vector2.ZERO


func squash_and_stretch():
	var ratio=velocity.length()/MAXSPEED
	var n=velocity.normalized()
	squash.scale=lerp(squash.scale, ((max_squash-min_squash)*ratio+max_squash)*n, .2)
	squash.skew=lerp(squash.skew, -velocity.angle(), .2)

## Occurs when player dies. (aint no way)
func die():
	print('died')
	death.emit()


func set_grapple_line_origin(p:Vector2):
	line.points[0]=p


func _on_obj_collider_area_entered(area: Area2D) -> void:
	if area.is_in_group('object'):
		match area.get_meta('type'):
			"speed_boost":
				camera.chain_zoom([[.24, .06], [.2, .5]])
				if (velocity*2).length()<MAXBOOSTSPEED:
					velocity*=2
				else:
					velocity+=velocity.normalized()*MAXBOOSTSPEED


func _on_obj_collider_area_exited(area: Area2D) -> void:
	pass

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group('enemy') and area.is_in_group('hitbox') and velocity.length()>=ATTACKINGSPEED:
		var p=area.get_parent()
		p.damage(floor(velocity.length()/ATTACKINGSPEED))
		camera.shake(4, .2)
		Global.timed_pause(.03)
		if !in_air:
			if jump_buffer>0:
				jump_buffer=0
				style_jump(.1)
			else:
				style_jump_frames=STYLEFRAMES
	elif area.is_in_group('object'):
		match area.get_meta('type'):
			'dumpster':
				if velocity.length()>=ATTACKINGSPEED:
					camera.shake(16, .2)
					area.get_parent().velocity=velocity
					velocity=-velocity*.8


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group('enemy'):
		ui.damage()


func _on_grapple_timer_timeout() -> void:
	if grappler!=null:
		grappler.destroy()
