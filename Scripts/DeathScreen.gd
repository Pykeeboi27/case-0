extends CanvasLayer

@onready var restart_button : Button = $Center/VBox/RestartButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
