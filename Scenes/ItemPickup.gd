extends Area3D

@export var item_data: Resource

func interact(player):
	if player.pickup_item(item_data):
		queue_free()

func _ready():
	if item_data and item_data.mesh_scene:
		var mesh = item_data.mesh_scene.instantiate()
		add_child(mesh)
