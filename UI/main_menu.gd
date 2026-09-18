extends Control

signal start_button_pressed
signal settings_button_pressed
signal quit_button_pressed
signal leaderboard_button_pressed

@onready var title_texture: TextureRect = $MarginContainer/VBoxContainer/VBoxContainer/Title

func _ready() -> void:
	$MarginContainer/VBoxContainer/Version.text = "v" + ProjectSettings.get_setting("application/config/version", "X.X.X")
	GameManager.game_screen_size = get_viewport_rect().size

	self.settings_button_pressed.connect(_on_settings_button_pressed)
	self.leaderboard_button_pressed.connect(_on_leaderboard_button_pressed)
	self.quit_button_pressed.connect(_on_quit_button_pressed)
	self.start_button_pressed.connect(_on_start_button_pressed)

	_pulsate()

func _on_start_button_pressed() -> void:
	UiManager.emit_signal("opened_start_menu")

func _on_quit_button_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	UiManager.emit_signal("opened_settings")

func _on_leaderboard_button_pressed() -> void:
	UiManager.emit_signal("opened_leaderboard")

func _pulsate() -> void:
	var PULSATE_PERIOD: float = 0.5
	var initial_title_y = title_texture.position.y
	while 1 > 0:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(title_texture, "position", Vector2(title_texture.position.x, initial_title_y + 3), PULSATE_PERIOD).set_trans(Tween.TRANS_CUBIC).set_delay(PULSATE_PERIOD * 0.74)
		tween.tween_property(title_texture, "position", Vector2(title_texture.position.x, initial_title_y), PULSATE_PERIOD).set_trans(Tween.TRANS_CUBIC).set_delay(PULSATE_PERIOD * 0.74 + PULSATE_PERIOD)
		await tween.finished
