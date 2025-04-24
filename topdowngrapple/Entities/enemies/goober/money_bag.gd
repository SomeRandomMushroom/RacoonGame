extends Area2D
@onready var coin=preload("res://Entities/enemies/goober/coin.tscn")
var velocity=Vector2.ZERO
func _physics_process(delta: float) -> void:
	position+=velocity*delta
	rotate(.2)


func collide():
	AudioManager.create_2d_audio_at_location(position, SoundEffect.SOUND_EFFECT_TYPE.COINBAG)
	var p
	for x in [Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]:
		p=coin.instantiate()
		add_sibling(p)
		p.position=position
		p.velocity=x.normalized()*200
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('wall'):
		collide()


func _on_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area.is_in_group('hitbox') and 'Player' in area.get_parent().name:
		collide()
