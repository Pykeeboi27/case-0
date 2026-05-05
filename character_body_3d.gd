# vii.gd
extends CharacterBody3D

enum State { ROAMING, CHASING, STUNNED }

@export var move_speed      : float = 3.5
@export var detect_radius   : float = 12.0
@export var stun_duration   : float = 3.0
@export var roam_radius     : float = 15.0

@onready var nav_agent  : NavigationAgent3D = $NavigationAgent3D
@onready var anim       : AnimationPlayer   = $AnimationPlayer

var state        : State = State.ROAMING
var player       : Node3D
var stun_timer   : float = 0.0
var roam_origin  : Vector3

func _ready() -> void:
	roam_origin = global_position
	player = get_tree().get_first_node_in_group("player")
	_pick_roam_target()

func _physics_process(delta: float) -> void:
	match state:
		State.ROAMING:  _roam(delta)
		State.CHASING:  _chase(delta)
		State.STUNNED:  _stunned(delta)

# ── Roaming ─────────────────────────────────────────────
func _roam(delta: float) -> void:
	_check_player_distance()   # runs every frame; lightweight

	if nav_agent.is_navigation_finished():
		_pick_roam_target()

	_move_toward_target(delta)
	anim.play("walk")

func _pick_roam_target() -> void:
	var offset := Vector3(
		randf_range(-roam_radius, roam_radius),
		0.0,
		randf_range(-roam_radius, roam_radius)
	)
	nav_agent.target_position = roam_origin + offset

# ── Detection ───────────────────────────────────────────
func _check_player_distance() -> void:
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= detect_radius:
		state = State.CHASING

# ── Chasing ─────────────────────────────────────────────
func _chase(delta: float) -> void:
	if player == null:
		state = State.ROAMING
		return

	var dist := global_position.distance_to(player.global_position)
	if dist > detect_radius * 1.3:      # small hysteresis prevents flicker
		state = State.ROAMING
		_pick_roam_target()
		return

	nav_agent.target_position = player.global_position
	_move_toward_target(delta)
	anim.play("run")

# ── Shared movement ─────────────────────────────────────
func _move_toward_target(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return
	var next_pos  := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity       = direction * move_speed
	move_and_slide()

	# Face movement direction
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

# ── Stun (called by player's shooting system) ───────────
func stun() -> void:
	state      = State.STUNNED
	stun_timer = stun_duration
	velocity   = Vector3.ZERO
	anim.play("stunned")

func _stunned(delta: float) -> void:
	stun_timer -= delta
	if stun_timer <= 0.0:
		state = State.ROAMING
		_pick_roam_target()
		anim.play("walk")
