extends Node3D

var is_open = false
var is_locked = false
var opened_once = false
@export var required_item: String
@export var target_door: String
@onready var animationplayer = $Door/AnimationPlayer
@onready var interact_door = $CanvasLayer/HBoxContainer/Label
@onready var timer = $Timer
	
func interact(player):
	if !is_open and !is_locked and player.item_target_use == target_door:
		open_door()
	elif is_open and !is_locked:
		close_door()
	else:
		interact_door.text = "You need " + required_item + " to open this door"
		timer.start(1)
		
func open_door():
	animationplayer.play("door_open")
	await animationplayer.animation_finished
	is_open = true

func close_door():
	animationplayer.play("door_close")
	await animationplayer.animation_finished
	is_open = false
	
func _on_timer_timeout() -> void:
	interact_door.text = ""
