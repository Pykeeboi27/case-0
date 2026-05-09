extends Node3D

var is_open = false
var opened_once = false
@onready var animationplayer = $"../../AnimationPlayer"
@onready var jump_scare_sound = $"../../../RandomJumpScare"

func _ready() -> void:
	randomize()

func interact(player):
	if !is_open:
		open_drawer()
	elif is_open:
		close_drawer()
		
func open_drawer():
	animationplayer.play("drawer_open")
	if opened_once == false:
		var jump_scare_chance = randi_range(0, 100)
		if jump_scare_chance < 36:
			var all_jump_scare = jump_scare_sound.get_children()
			var chosen_jump_scare = all_jump_scare.pick_random()
			chosen_jump_scare.play()
	opened_once = true
	await animationplayer.animation_finished
	is_open = true
	

func close_drawer():
	animationplayer.play("drawer_close")
	await animationplayer.animation_finished
	is_open = false
