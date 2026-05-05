extends CharacterBody3D

@export var move_speed     : float = 3.5
@export var chase_speed    : float = 5.5
@export var roam_radius    : float = 10.0
@export var detect_radius  : float = 12.0
@export var stun_duration  : float = 3.0

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D

enum State { ROAMING, CHASING, STUNNED }

var state       : State = State.ROAMING
var roam_origin : Vector3
var player      : Node3D
var stun_timer  : float = 0.0

func _ready() -> void:
	roam_origin = global_position
	player = get_tree().get_first_node_in_group("player")
	await get_tree().physics_frame
	_pick_roam_target()

func _physics_process(delta: float) -> void:
	match state:
		State.ROAMING: _roam()
		State.CHASING: _chase()
		State.STUNNED: _stunned(delta)

# ── Roaming ─────────────────────────────────────────────

func _roam() -> void:
	_check_player_distance()

	if nav_agent.is_navigation_finished():
		_pick_roam_target()
		return

	_move_toward_target(move_speed)

func _pick_roam_target() -> void:
	var random_target : Vector3
	var attempts := 0

	while attempts < 10:
		var offset := Vector3(
			randf_range(-roam_radius, roam_radius),
			0.0,
			randf_range(-roam_radius, roam_radius)
		)
		var candidate := roam_origin + offset
		var closest := NavigationServer3D.map_get_closest_point(
			nav_agent.get_navigation_map(),
			candidate
		)
		if closest.distance_to(candidate) < 1.0:
			random_target = candidate
			break
		attempts += 1

	nav_agent.target_position = random_target if attempts < 10 else roam_origin

# ── Detection ───────────────────────────────────────────

func _check_player_distance() -> void:
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= detect_radius:
		state = State.CHASING

# ── Chasing ─────────────────────────────────────────────

func _chase() -> void:
	if player == null:
		state = State.ROAMING
		return

	var dist := global_position.distance_to(player.global_position)

	# Lost the player — go back to roaming
	if dist > detect_radius * 1.3:
		state = State.ROAMING
		_pick_roam_target()
		return

	nav_agent.target_position = player.global_position
	_move_toward_target(chase_speed)

# ── Shared movement ─────────────────────────────────────

func _move_toward_target(speed: float) -> void:
	if nav_agent.is_navigation_finished():
		return

	var next_pos  := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	direction.y   = 0.0

	if direction.length() < 0.01:
		return

	velocity = direction * speed
	move_and_slide()
	look_at(global_position + direction, Vector3.UP)

# ── Stunned ─────────────────────────────────────────────

func stun() -> void:
	state      = State.STUNNED
	stun_timer = stun_duration
	velocity   = Vector3.ZERO

func _stunned(delta: float) -> void:
	velocity    = Vector3.ZERO
	move_and_slide()
	stun_timer -= delta
	if stun_timer <= 0.0:
		state = State.ROAMING
		_pick_roam_target()
