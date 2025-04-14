extends Node2D

@export var MAXHEALTH=10.0

@onready var break_particle=preload('res://effects/burst/hat_break.tscn')
@onready var hatheight=$Height

var current_health=MAXHEALTH
var previous_health=current_health
var toggle=false

signal empty

func _ready() -> void:
	update()

func update():
	hatheight.size.y=16.0+current_health*2
	if current_health<=0:
		empty.emit()
		return
	if previous_health>current_health:
		var p=break_particle.instantiate()
		if is_instance_valid(Global.current_level):
			Global.current_level.add_child(p)
		else:
			add_sibling(p)

		p.position=global_position+Vector2.from_angle(rotation+Global.rad_90)*(-8-current_health*.2)
		p.rotation=rotation
		p.scale_curve_y.set_point_value(0, (previous_health-current_health)*.35)
	previous_health=current_health
