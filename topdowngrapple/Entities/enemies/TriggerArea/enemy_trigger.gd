extends Area2D

@export var connected_enemies: Array[Node]


func _on_body_entered(body: Node2D) -> void:
	if 'player' in body.name:
		for x in connected_enemies:
			x.aggrevated=true
