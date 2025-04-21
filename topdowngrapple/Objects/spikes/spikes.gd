extends TextureRect

var contains_player=false
var ready_to_damage=true


func _physics_process(delta: float) -> void:
	if contains_player and ready_to_damage and not Global.player.in_air:
		Global.player.damage()
		ready_to_damage=false
		$cooldown.start()
		print('spiky')


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name=='Player':
		contains_player=true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name=='Player':
		contains_player=false
		ready_to_damage=true


func _on_cooldown_timeout() -> void:
	ready_to_damage=true
