extends Control

@onready var max_size=$Max.size.x
@onready var current=$Current
@export var max_value=5.0
@export var color=Color(1, 1, 1, 1)
var current_value


func _ready() -> void:
	current_value=max_value
	current.color=color
	current.size.x=max_size
	$Max.color=color.darkened(.4)


func change_value(n=1):
	current_value+=n
	current.size.x=max_size*(current_value/max_value)
