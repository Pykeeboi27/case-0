extends MeshInstance3D

var is_open = false
@onready var animationplayer = $"../AnimationPlayer"

func interact(player):
	if !is_open:
		open_drawer()
	if is_open:
		close_drawer()
		
func open_drawer():
	animationplayer.play("drawer_open")
	is_open = true

func close_drawer():
	animationplayer.play("drawer_close")
	is_open = false
