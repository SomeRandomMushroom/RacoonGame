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
		death.emit()


func decrease_energy(n=1):
	energy-=n
	if energy<=-energy_bar.max_value/2:
		energy=-energy_bar.max_value/2
	energy=min(energy, energy_bar.max_value)
	energy_bar.set_value(energy)
