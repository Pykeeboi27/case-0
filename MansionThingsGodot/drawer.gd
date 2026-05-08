extends MeshInstance3D

var is_open = false
var opened_once = false
@onready var animationplayer = $"../AnimationPlayer"

func _ready() -> void:
	randomize()

func interact(player):
	if !is_open:
		open_drawer()
	if is_open:
		close_drawer()
		
func open_drawer():
	animationplayer.play("drawer_open")
	is_open = true
	if opened_once == false:
		var jump_scare_chance = randi_range(0, 100)
		if jump_scare_chance < 26:
			pass
		opened_once = true;

func close_drawer():
	animationplayer.play("drawer_close")
	is_open = false
