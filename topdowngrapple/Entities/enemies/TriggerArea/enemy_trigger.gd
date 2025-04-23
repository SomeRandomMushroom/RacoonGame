extends Area2D

@export var connected_enemies: Array[Node]
@export var connected_objects: Array[Node]

var used_up=false
var num_enemies=0


func enemy_died():
	num_enemies-=1
	if num_enemies<=0:
		connected_enemies.clear()
		if len(connected_objects)>0:
			for x in connected_objects:
				x.switch()


func _on_body_entered(body: Node2D) -> void:
	if 'Player' in body.name and not used_up:
		for x in connected_enemies:
			x.aggrevated=true
			num_enemies+=1
			x.connect('death', enemy_died)
		used_up=true
