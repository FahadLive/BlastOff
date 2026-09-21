extends Control

const status_messages = {
	"game_over": "Game Over",
}

var active_warnings: Dictionary = {}

const STAR_VISIBLE_TIME: float = 5

@onready var score_label = $WholeScreen/ScoreBox/Panel/VBoxContainer/Score
@onready var warning_sign: AnimatedSprite2D = $WarningSign
@onready var powerup_progress: TextureProgressBar = $WholeScreen/HBoxContainer/VBoxContainer/CenterContainer/TextureProgressBar

enum PROGRESS_BAR_TYPES {
	NORMAL,
	INUSE
}

const PROGRESS_BAR_TEXTURES = {
	PROGRESS_BAR_TYPES.NORMAL: preload("res://Collectables/powerup_progress_bar.svg"),
	PROGRESS_BAR_TYPES.INUSE: preload("res://Collectables/powerup_progress_bar_in_use.svg")
}

const POWERUP_ICONS: Dictionary = {
	SpawnManager.SHIELD: preload("res://Collectables/Shield/shield_icon.svg"),
	SpawnManager.BOOST: preload("res://Collectables/Boost/boost_icon.svg")
}

var powerup_reduction_tween: Tween

var is_warning_on: bool = false

var is_powerup_depleting: bool = true
var current_powerup_usage: float

func _ready() -> void:
	UiManager.warning_announced.connect(_flash_warning)
	UiManager.warning_withdrawn.connect(_stop_warning)

	PowerupManager.collected_powerup.connect(setup_powerup_button)
	PowerupManager.powerup_depleted.connect(disable_powerup)

	PowerupManager.use_powerup.connect(_on_use_powerup)
	PowerupManager.stop_powerup.connect(_on_stop_powerup)

	PowerupManager.reduce_powerup_lifetime.connect(_on_reduce_powerup_lifetime)

	disable_powerup()

func _physics_process(delta: float) -> void:
	score_label.text = "{score}".format({"score": StatManager.score_gained})
	UiManager.star_count_global_pos = $WholeScreen/ScoreBox/Panel/VBoxContainer/StarCount.global_position
	if is_powerup_depleting:
		deplete_powerup(delta)

func _flash_warning(x_position: float, warning_id: int):
	var vertical_screen_size: float = get_viewport_rect().size.y

	var new_warning_sign: AnimatedSprite2D = warning_sign.duplicate()

	active_warnings[str(warning_id)] = new_warning_sign
	add_child(new_warning_sign)
	new_warning_sign.position = Vector2(x_position, (0.1 * vertical_screen_size))
	new_warning_sign.show()

func _stop_warning(warning_id: int):
	if not active_warnings.has(str(warning_id)):
		return

	var active_warning_sign: Node = active_warnings.get(str(warning_id))

	if not active_warning_sign: # Prevent it from trying to deleteit twice
		return

	active_warning_sign.hide()
	active_warning_sign.queue_free()
	active_warnings.erase(str(warning_id))

func _on_powerup_button_toggled(toggle_state: bool) -> void:
	if toggle_state:
		PowerupManager.emit_signal("use_powerup", PowerupManager.current_active_powerup)
	else:
		PowerupManager.emit_signal("stop_powerup")

func disable_powerup() -> void:
	powerup_progress.texture_progress = PROGRESS_BAR_TEXTURES.get(PROGRESS_BAR_TYPES.NORMAL)
	powerup_progress.value = 0
	current_powerup_usage = powerup_progress.value

	is_powerup_depleting = false

	powerup_progress.self_modulate.a = 0.5 # Make it translucent

func setup_powerup_button(powerup_type: int) -> void:

	powerup_progress.value = 100
	current_powerup_usage = powerup_progress.value

	is_powerup_depleting = true
	powerup_progress.self_modulate.a = 1 # Make it opaque

func deplete_powerup(delta: float) -> void:
	current_powerup_usage -= PowerupManager.POWERUP_USAGE_RATE.get(PowerupManager.current_powerup_stage) * delta
	clamp(current_powerup_usage, 0, 100)

	powerup_progress.value = current_powerup_usage
	if powerup_progress.value == 0:
		PowerupManager.emit_signal("powerup_depleted")


func _on_reduce_powerup_lifetime(percent_reduction: int = 0):

	const FADE_LIFETIME: float = 0.2

	if powerup_reduction_tween and powerup_reduction_tween.is_running():
		powerup_reduction_tween.stop()
		powerup_reduction_tween.kill()

	powerup_reduction_tween = create_tween().set_parallel(true)

	powerup_reduction_tween.tween_property(powerup_progress, "modulate", Color.RED,FADE_LIFETIME)
	powerup_reduction_tween.tween_property(powerup_progress, "modulate", Color.WHITE, FADE_LIFETIME).set_delay(FADE_LIFETIME)

	current_powerup_usage -= percent_reduction

# To display powerup uage on button, when the powerup is used in any other methods (like shortcut keys)
func _on_use_powerup(_type: int) -> void:
	powerup_progress.texture_progress = PROGRESS_BAR_TEXTURES.get(PROGRESS_BAR_TYPES.INUSE)


func _on_stop_powerup() -> void:
	powerup_progress.texture_progress = PROGRESS_BAR_TEXTURES.get(PROGRESS_BAR_TYPES.NORMAL)
