extends Node

signal inventory_changed
signal slot_selected

@export var HOTBAR_SIZE: int = 4
@export var default_items: Array[Resource] = []

var hotbar: Array = []
var selected_slot: int
var current_battery: int = 1000
var max_battery: int = 1000

func _ready():
	hotbar.resize(HOTBAR_SIZE)
	
	default_items = [
		preload("res://Assets/items/flashlight.tres"),
	]
	for i in range(min(default_items.size(), HOTBAR_SIZE)):
		hotbar[i] = default_items[i]

	emit_signal("inventory_changed")
	select_slot(0)
	

func add_item(item):
	for i in range(HOTBAR_SIZE):
		if hotbar[i] == null:
			hotbar[i] = item
			emit_signal("inventory_changed")
			select_slot(i)
			return true
	return false

func select_slot(index):
	selected_slot = clamp(index, 0, HOTBAR_SIZE - 1)
	emit_signal("slot_selected", selected_slot)
