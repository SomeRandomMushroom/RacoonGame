extends Node2D


func _on_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Levels/title_screen.tscn")
