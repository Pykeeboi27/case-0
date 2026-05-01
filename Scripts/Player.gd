extends CharacterBody3D #physics
@export var moveSpeed: float = 5.0
@export var jumpForce: float = 10.0
@export var gravity: float = 30.0

#camera look
var minLookAngle: float = -90.0
var maxLookAngle: float = 90.0
var lookSensitivity: float = 0.2

#vectors
var mouseDelta: Vector2 = Vector2()

#Physics and Pick up Objects
var pickedObject
var objectPullPower: float = 4.0
var current_item = null
var item_target_use: String = "none"

# --- HEAD BOB ---
@export var bobFrequency: float = 20.0
@export var bobAmplitudeY: float = 0.12   # up/down
@export var bobAmplitudeX: float = 0.08   # left/right

var bobTime: float = 0.0
var cameraDefaultPosition: Vector3
# ----------------

#player components
@onready var camera = get_node("Camera3D")
@onready var interaction = get_node("Camera3D/Interaction")
@onready var hand = get_node("Camera3D/Hand")
@onready var labeltext = $CanvasLayer/InteractContainer/InteractLabel
@onready var itemhand = get_node("Camera3D/ItemHand")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set fullscreen (Godot 4 way)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	cameraDefaultPosition = camera.position
	Inventory.connect("slot_selected", Callable(self, "_on_slot_selected"))

func _input(event):
	#mouse movement
	if event is InputEventMouseMotion:
		mouseDelta = event.relative
	
	if event.is_action_pressed("slot_1"):
		Inventory.select_slot(0)
	elif event.is_action_pressed("slot_2"):
		Inventory.select_slot(1)
	elif event.is_action_pressed("slot_3"):
		Inventory.select_slot(2)
	elif event.is_action_pressed("slot_4"):
		Inventory.select_slot(3)
	

func _process(delta):
	#rotate camera along x-axis
	camera.rotation_degrees -= Vector3(rad_to_deg(mouseDelta.y),0,0)*lookSensitivity*delta
	#clamp the vertical camera rotation
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, minLookAngle, maxLookAngle)
	#rotate player along y-axis
	rotation_degrees -= Vector3(0, rad_to_deg(mouseDelta.x), 0)*lookSensitivity*delta
	#reset the mouse delta vector
	mouseDelta = Vector2()

func _physics_process(delta):
	#reset the x and z velocity
	velocity.x = 0
	velocity.z = 0

	var input = Vector2()

	#movement inputs
	if Input.is_action_pressed("move_forward"):
		input.y -= 1
	if Input.is_action_pressed("move_backward"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1

	#normalize the input so no faster movement diagonally
	input = input.normalized()

	#get out forward and right directions
	var forward = global_transform.basis.z
	var right = global_transform.basis.x
	velocity.z = (forward*input.y + right*input.x).z * moveSpeed
	velocity.x = (forward*input.y + right*input.x).x * moveSpeed

	#apply gravity
	velocity.y -= gravity * delta

	#move the player
	move_and_slide()

	#jump
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jumpForce

	# --- HEAD BOB ---
	var isMoving = input.length() > 0 and is_on_floor()

	if isMoving:
		bobTime += delta * bobFrequency
		
		var bobY = sin(bobTime) * bobAmplitudeY
		var bobX = cos(bobTime * 0.5) * bobAmplitudeX  # slower sway for realism
		
		camera.position.x = cameraDefaultPosition.x + bobX
		camera.position.y = cameraDefaultPosition.y + bobY
	else:
		bobTime = 0.0
		camera.position = camera.position.lerp(cameraDefaultPosition, delta * 8.0)
	# ----------------

	#picking up and dropping objects
	if Input.is_action_just_pressed('pick_up'):
		pickObjects()
	if Input.is_action_just_pressed('drop'):
		dropObjects()

	#picking up objects from rayCast to postion3D
	if pickedObject != null:
		var a = pickedObject.global_transform.origin
		var b = hand.global_transform.origin
		pickedObject.set_linear_velocity((b-a)*objectPullPower)
	
	labeltext.hide()
	
	if interaction.is_colliding():
		var target = interaction.get_collider()
		if target != null and target.has_method("interact"):
			labeltext.show()
				
			if Input.is_action_just_pressed("interact"):
				target.interact(self)
			
func window_activity():
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pickObjects():
	var collider = interaction.get_collider()
	if collider != null and collider is RigidBody3D:
		print("Test if working")
		pickedObject = collider

func dropObjects():
	if pickedObject != null:
		print("Dropping?")
		pickedObject = null
		
func pickup_item(item):
	return Inventory.add_item(item)

func _on_slot_selected(index):
	var item = Inventory.hotbar[index]

	if current_item:
		current_item.queue_free()
		current_item = null

	if item and item.mesh_scene:
		current_item = item.mesh_scene.instantiate()
		item_target_use = item.target_use
		current_item.is_equipped = true
		itemhand.add_child(current_item)
