extends Area3D

@export var item_data: Resource

func interact(player):
	if player.pickup_item(item_data):
		queue_free()

func _ready():
	if item_data and item_data.mesh_scene:
		var mesh = item_data.mesh_scene.instantiate()
		var mesh_node = mesh.find_children("*","MeshInstance3D")[0]
		if mesh_node and mesh_node is MeshInstance3D:
			var mesh_resource = mesh_node.mesh
			var collision_shape = mesh_resource.create_convex_shape()
			$CollisionShape3D.shape = collision_shape
			$CollisionShape3D.scale = mesh_node.scale
		add_child(mesh)
