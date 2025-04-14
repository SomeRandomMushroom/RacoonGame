extends Area2D

@onready var shape=$Polygon2D
@onready var collider=$CollisionShape2D

const FORCE=150
var size=1


func _ready() -> void:
	call_deferred('setup')

func setup():
	collider.shape.radius=64*size
	shape.scale=Vector2.ONE*size



func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area.is_in_group('enemy') and area.is_in_group('hitbox'):
		var p=area.get_parent()
		p.damage(floor(size))
		p.velocity=position.direction_to(p.position)*FORCE*size


func _on_timer_timeout() -> void:
	monitoring=false


func _on_land_shockwave_effect_2_finished() -> void:
	queue_free()
