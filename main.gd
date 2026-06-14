extends Node

@onready var bg_music_list: Array = [
	preload("res://Music/bravery_demon.ogg"),
	preload("res://Music/bravery_run.ogg"),
	preload("res://Music/homely_arcade.ogg")
]

@onready var music_player = $Music

var is_game_running: bool = false

# Related to screen shake
var current_shake_strength = 0;

func _ready() -> void:
	GameManager.game_started.connect(restart_game)
	GameManager.game_over.connect(_on_game_over)

	UiManager.main_scene = self
	UiManager.emit_signal("skipped_to_main_menu")
	UiManager.triggered_screen_shake.connect(_activate_screen_shake)

	_start_rand_music()

func _on_game_over() -> void:
	is_game_running = false

func restart_game() -> void:
	is_game_running = true

func _on_music_finished() -> void:
	_start_rand_music()

func _start_rand_music() -> void:
	music_player.stream = bg_music_list.pick_random()
	music_player.play()

func _process(delta):
	# To calculate screenshake
	if current_shake_strength != 0:
		current_shake_strength = max(current_shake_strength - delta, 0);

		$ScreenShake/ColorRect.material.set_shader_parameter("ShakeStrength", max(current_shake_strength,0))

func _activate_screen_shake(shake_type: int = UiManager.STRENGTH_TYPES.MED) -> void:
	var triggered_shake_strength = UiManager.SHAKE_STRENGTHS.get(shake_type)
	current_shake_strength = triggered_shake_strength
