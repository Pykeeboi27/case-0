extends HBoxContainer

var slots = []

func _ready():
	slots = get_children()

	for i in range(slots.size()):
		slots[i].connect("pressed", Callable(self, "_on_slot_pressed").bind(i))

	Inventory.connect("inventory_changed", Callable(self, "_update_hotbar"))
	Inventory.connect("slot_selected", Callable(self, "_highlight_slot"))

	_update_hotbar()
	_highlight_slot(Inventory.selected_slot)

func _update_hotbar():
	for i in range(slots.size()):
		var item = Inventory.hotbar[i]
		if item:
			slots[i].texture_normal = item.icon
		else:
			slots[i].texture_normal = null

func _highlight_slot(index):
	for i in range(slots.size()):
		slots[i].modulate = Color(1,1,1)
	slots[index].modulate = Color(1.5,1.5,1.5)

func _on_slot_pressed(index):
	Inventory.select_slot(index)
