extends CharacterBody3D

@export var move_speed     : float = 3.5
@export var chase_speed    : float = 5.5
@export var roam_radius    : float = 10.0
@export var detect_radius  : float = 12.0
@export var attack_range   : float = 1.8
@export var attack_damage  : float = 20.0
@export var attack_windup  : float = 0.45
@export var stun_duration  : float = 3.0

@onready var nav_agent    : NavigationAgent3D = $NavigationAgent3D
@onready var anim_player  : AnimationPlayer   = $AnimationPlayer

enum State { ROAMING, CHASING, STUNNED, ATTACKING, DEAD }

var state       : State = State.ROAMING
var roam_origin : Vector3
var player      : Node3D
var stun_timer  : float = 0.0
var frozen      : bool  = false

var _meshes        : Array[Node] = []
var _freeze_mat    : StandardMaterial3D
var _attack_timer  : float = 0.0
var _attack_landed : bool = false

func _ready() -> void:
	roam_origin = global_position
	player = get_tree().get_first_node_in_group("player")

	$AnimationTree.active = false          # AnimationPlayer drives the model directly
	anim_player.animation_finished.connect(_on_animation_finished)
	_play("Idle")

	_build_freeze_material()
	_meshes = find_children("*", "MeshInstance3D", true, false)

	await get_tree().physics_frame
	_pick_roam_target()

func _physics_process(delta: float) -> void:
	match state:
		State.ROAMING:   _roam()
		State.CHASING:   _chase()
		State.STUNNED:   _stunned(delta)
		State.ATTACKING: _attacking(delta)
		State.DEAD:      pass

# ── Animation ───────────────────────────────────────────

func _play(anim_name: StringName) -> void:
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name, 0.2)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Stab" and state == State.ATTACKING:
		state = State.CHASING if player else State.ROAMING

# ── Roaming ─────────────────────────────────────────────

func _roam() -> void:
	_check_player_distance()

	if nav_agent.is_navigation_finished():
		_play("Idle")
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

	# Close enough — attack
	if dist <= attack_range:
		_start_attack()
		return

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
		_play("Idle")
		return

	var next_pos  := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	direction.y   = 0.0

	if direction.length() < 0.01:
		_play("Idle")
		return

	velocity = direction * speed
	move_and_slide()
	look_at(global_position + direction, Vector3.UP)
	_play("Walk")

# ── Attacking ───────────────────────────────────────────

func _start_attack() -> void:
	state    = State.ATTACKING
	velocity = Vector3.ZERO
	move_and_slide()
	_attack_timer  = attack_windup
	_attack_landed = false
	_play("Stab")

func _attacking(delta: float) -> void:
	velocity = Vector3.ZERO
	move_and_slide()

	# Keep facing the player while the stab plays
	if player:
		var to_player := player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.01:
			look_at(global_position + to_player, Vector3.UP)

	# Land the hit once, partway through the stab
	if not _attack_landed:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_landed = true
			_land_hit()

func _land_hit() -> void:
	if player == null or not player.has_method("take_damage"):
		return
	if global_position.distance_to(player.global_position) <= attack_range:
		player.take_damage(attack_damage)

# ── Stunned / Frozen ────────────────────────────────────

func stun() -> void:
	if state == State.DEAD:
		return
	state      = State.STUNNED
	stun_timer = stun_duration
	velocity   = Vector3.ZERO

func freeze(duration: float) -> void:
	if state == State.DEAD:
		return
	state      = State.STUNNED
	stun_timer = duration
	velocity   = Vector3.ZERO
	_set_frozen(true)

func _set_frozen(on: bool) -> void:
	frozen = on
	for mesh in _meshes:
		mesh.material_override = _freeze_mat if on else null

func _build_freeze_material() -> void:
	_freeze_mat = StandardMaterial3D.new()
	_freeze_mat.albedo_color = Color(0.55, 0.8, 1.0, 0.7)
	_freeze_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_freeze_mat.emission_enabled = true
	_freeze_mat.emission = Color(0.4, 0.7, 1.0)

func _stunned(delta: float) -> void:
	velocity    = Vector3.ZERO
	move_and_slide()
	_play("Idle")
	stun_timer -= delta
	if stun_timer <= 0.0:
		if frozen:
			_set_frozen(false)
		state = State.ROAMING
		_pick_roam_target()

# ── Death ───────────────────────────────────────────────

func die() -> void:
	if state == State.DEAD:
		return
	if frozen:
		_set_frozen(false)
	state    = State.DEAD
	velocity = Vector3.ZERO
	move_and_slide()
	_play("Death")
