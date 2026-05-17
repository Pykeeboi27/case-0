extends Node3D

# DESISTO wand — casts a freeze spell on nearby enemies.

@export var spell_radius    : float = 12.0
@export var freeze_duration : float = 5.0
@export var cooldown        : float = 6.0

var is_equipped : bool = false
var target_use  : String = "wand"

var _cooldown_timer : float = 0.0

@onready var tip_light : OmniLight3D = $TipLight

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	# Cast flash settles back to the idle glow
	if tip_light:
		tip_light.light_energy = lerp(tip_light.light_energy, 0.6, delta * 4.0)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("cast_spell") and is_equipped and _cooldown_timer <= 0.0:
		_cast_desisto()

func _cast_desisto() -> void:
	_cooldown_timer = cooldown

	if tip_light:
		tip_light.light_energy = 8.0

	var origin := global_position
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node3D and enemy.has_method("freeze") \
		and origin.distance_to(enemy.global_position) <= spell_radius:
			enemy.freeze(freeze_duration)
