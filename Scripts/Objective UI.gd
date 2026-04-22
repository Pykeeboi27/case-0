extends Control

@onready var label = $Panel/ObjectiveText

func _ready():
	visible = false

func show_objective(text: String, duration := 3.0):
	label.text = text
	visible = true
	
	await get_tree().create_timer(duration).timeout
	visible = false
