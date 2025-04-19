extends Node2D

@export var slope_vector= Vector2(6, -1)

var slope=0
var connected_obj={}


func _ready() -> void:
	slope=slope_vector.y/slope_vector.x


func _physics_process(_delta: float) -> void:
	for x in connected_obj.keys():
		x.vis.position.y=(x.position.x-position.x)*slope


func add_obj(body):
	connected_obj[body]=body.global_position.y


func _on_enter_point_body_entered(body: Node2D) -> void:
	if body is not StaticBody2D and body is not TileMapLayer and body.in_air==false:
		add_obj(body)


func _on_ramp_tile_body_exited(body: Node2D) -> void:
	if body in connected_obj.keys():
		body.in_air=true
		body.z_pos=body.vis.position.y
		body.draw_layer.position.y=body.z_pos
		body.z_vel=body.velocity.length()*slope*get_process_delta_time()
		body.vis.set_deferred('position', Vector2.ZERO)
		if body == Global.player:
			body.wall_riding=false
			body.prev_vel_speed=body.velocity.length()
			body.off_ramp()
		connected_obj.erase(body)
