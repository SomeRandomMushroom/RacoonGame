extends Area2D
@export var attatched_objects:Array[Node]


func _on_body_entered(body: Node2D) -> void:
	if 'Player' in body.name:
		for x in attatched_objects:
			x.close()
