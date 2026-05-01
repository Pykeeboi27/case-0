extends Node3D

var flashlight_on := false
var is_equipped = false
var target_use: String = "none"

@onready var batteryicon = $Battery

func _ready():
	if not is_equipped:
		batteryicon.hide()
		
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("flashlight") and is_equipped:
		if $Battery.value > 0 or flashlight_on:
			flashlight_on = !flashlight_on
	
	$SpotLight3D.light_energy = 16 if flashlight_on else 0

func _physics_process(delta: float) -> void:
	$Battery.value = Inventory.current_battery
	if flashlight_on and $Battery.value > 0:
		Inventory.current_battery -= 1
	else:
		flashlight_on = false
		$SpotLight3D.light_energy = 0
