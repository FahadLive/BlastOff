extends Area2D


@onready var back_shine_node = $SpriteBack
@onready var star_sptite: Sprite2D = $Sprite

@onready var collision_shape = $CollisionShape2D
@onready var collection_sound_node: AudioStreamPlayer = $CollectedSound

@export_enum("Star:2", "Shield:3", "Boost:4") var collectable_type: int = 2 # Change enums when adding new items

const BG_ANIM_TIME: float = 3

var initial_shine_scale: Vector2
var can_glow: bool = false
var can_sway: bool = false

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)

	if collectable_type == SpawnManager.STAR:
		_setup_star()
	else:
		_setup_drop_box()

func _setup_star() -> void:
	can_glow = true
	_glow()

func _setup_drop_box() -> void:
	can_sway = true
	_sway()

func _glow():
	initial_shine_scale = back_shine_node.scale
	while can_glow:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(back_shine_node, "scale", initial_shine_scale * 2, BG_ANIM_TIME / 2)
		tween.tween_property(back_shine_node, "scale", initial_shine_scale, BG_ANIM_TIME / 2).set_delay(BG_ANIM_TIME / 2)
		await tween.finished

func _sway():
	var initial_box_rotation: float = self.rotation_degrees
	while can_sway:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "rotation_degrees", initial_box_rotation + 5, BG_ANIM_TIME / 2)
		tween.tween_property(self, "rotation_degrees", initial_box_rotation - 5, BG_ANIM_TIME / 2).set_delay(BG_ANIM_TIME / 2)
		await tween.finished

func free_fall(delta) -> void:
	var moveable_y: float = (GameManager.rocket_speed * delta)

	self.position.y += moveable_y

func _physics_process(delta: float) -> void:
	free_fall(delta)

func make_disappear() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(back_shine_node, "scale", initial_shine_scale * 2, BG_ANIM_TIME / 2)
	tween.tween_property(back_shine_node, "modulate:a", 0, BG_ANIM_TIME / 2)
	await tween.finished

	free_obstacle()

func _on_hit() -> void:
	collision_shape.set_deferred("disabled", true)

	collection_sound_node.pitch_scale = randf_range(1, 1.5)
	collection_sound_node.play()

	$CPUParticles2D.emitting = true

	if collectable_type != SpawnManager.STAR:
		star_sptite.hide()
		back_shine_node.hide()
		UiManager.emit_signal("triggered_screen_shake", UiManager.STRENGTH_TYPES.MED)

	_on_collection()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	free_obstacle()

func _on_game_over() -> void:
	free_obstacle()

func _on_star_collected_sound_finished() -> void:
	if not collectable_type == SpawnManager.STAR:
		free_obstacle()

func free_obstacle() -> void:
	can_glow = false
	can_sway = false

	if not self.is_queued_for_deletion():
		SpawnManager.make_obstacle_free(self, collectable_type)

func _on_collection() -> void: # To be overriden in each collectable's script
	return
