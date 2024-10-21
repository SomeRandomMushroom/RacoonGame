extends CanvasLayer

@onready var health_bar=$HealthBar
@onready var energy_bar=$EnergyBar
@onready var health=health_bar.max_value
@onready var energy=energy_bar.max_value

signal death


func damage(n=1):
	health_bar.change_value(-n)
	health-=n
	if health<=0:
		emit_signal('death')


func decrease_energy(n=1):
	energy_bar.change_value(-n)
	energy-=n
	energy=min(energy, energy_bar.max_value)
