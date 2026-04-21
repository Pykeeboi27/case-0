extends Spatial

var flashlight_on := false
var is_equipped = false

onready var batteryicon = $Battery

func _ready():
	if not is_equipped:
		batteryicon.hide()
		
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("flashlight") and is_equipped:
		if $Battery.value > 0 or flashlight_on:
			flashlight_on = !flashlight_on
	
	$SpotLight.light_energy = 16 if flashlight_on else 0

func _physics_process(delta: float) -> void:
	if flashlight_on and $Battery.value > 0:
		$Battery.value -= 1
	else:
		flashlight_on = false
		$SpotLight.light_energy = 0
