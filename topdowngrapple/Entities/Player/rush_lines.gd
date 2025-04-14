extends Node2D

@export var p=CharacterBody2D

@onready var particles_white1=$CPUParticles2D
@onready var particles_white2=$CPUParticles2D3
@onready var particles_black1=$CPUParticles2D2
@onready var particles_black2=$CPUParticles2D4

const ROTATIONSPEED=.8
const rad_180=deg_to_rad(180)

var max_offset=65
var max_active=.5
var active=0.0
var pvel

func _physics_process(delta: float) -> void:
	pvel=p.velocity
	if pvel.length()>p.ATTACKINGSPEED*2: #TODO: continue fixing this right now
		active=max_active*((pvel.length()-p.ATTACKINGSPEED*2)/(p.MAXSPEED+p.ATTACKINGSPEED))
	else:
		active=0
	modulate=Color(1, 1, 1, active)

	if active>0:
		if abs(angle_difference(rotation, pvel.angle()+rad_180))>deg_to_rad(100):
			rotation+=rad_180
		rotation=lerp_angle(rotation, pvel.angle()+rad_180, ROTATIONSPEED*delta)#angle_difference(rotation, pvel.angle()+rad_180)*ROTATIONSPEED*delta)
		var offset=abs(Vector2.from_angle(rotation).y)*max_offset
		particles_white1.position.y=-74-offset
		particles_white2.position.y=74+offset
		particles_black1.position.y=-82-offset
		particles_black2.position.y=82+offset

#Thanks to Dlean James (https://forum.godotengine.org/t/lerp-rotation-with-above-180-degrees-difference/22090/3)
#func _lerp_angle(from, to, weight):
#	return from + _short_angle_dist(from, to) * weight
#func _short_angle_dist(from, to):
#	var difference = fmod(to - from, 2*PI)
#	return (fmod(2 * difference, 2*PI) - difference)*500
