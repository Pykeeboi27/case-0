extends CanvasLayer

func _ready():
	var label = $Panel
	
	label.modulate.a = 0
	label.show()

	var t = get_tree().create_timer(0.2)
	yield(t, "timeout")

	label.modulate.a = 1

	yield(get_tree().create_timer(3.0), "timeout")

	label.modulate.a = 0
	label.hide()
