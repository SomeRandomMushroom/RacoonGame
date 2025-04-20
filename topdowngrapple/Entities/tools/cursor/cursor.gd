extends Node2D
@onready var clicker=$Clickbox
@onready var aimer=$GrappleToAimer
@onready var line=$Line2D
const MAXCYOTEFRAMES=25
var colliding_objects=[]
var grapple_target=Vector2.ZERO
var prev_position=Vector2.ZERO
var cyote_frames=0


func _ready() -> void:
	if Global.player:
		Global.player.remote.remote_path=aimer.get_path()
	grapple_target=position


func _physics_process(_delta: float) -> void:
	position=get_global_mouse_position()
	if Global.player:
		aimer.target_position=(position-Global.player.position).normalized()*500
		if position!=prev_position:
			if aimer.is_colliding():
				grapple_target=aimer.get_collision_point()
				Global.player.aiming_to=grapple_target
				cyote_frames=MAXCYOTEFRAMES
			elif cyote_frames<=0:
				Global.player.aiming_to=position
			
			line.visible=true
			line.position=Global.player.position-position
			line.points[1]=Global.player.aiming_to-Global.player.position
			#line.points[1]=grapple_target

		if cyote_frames>0:
			cyote_frames-=1

		if Input.is_action_just_pressed('grapple') and Global.player.in_air:
			clicker.monitoring=true
		elif clicker.monitoring:
			if colliding_objects:
				colliding_objects.sort_custom(func(a, b): return a.position.distance_to(position)<b.position.distance_to(position) and a.position.distance_to(Global.player.position)>=24)
				if (colliding_objects[0].position.distance_to(Global.player.position)>=60):
					Global.player.air_grapple(colliding_objects[0])
				colliding_objects=[]
			clicker.monitoring=false


func _on_clickbox_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	colliding_objects.append(area.get_parent())
