@tool
extends TextureButton

@export var button_text: String = "Button":
	set(value):
		button_text = value
		$CenterContainer/Label.text = button_text

@export var pressed_signal_name: String :
	set(value):
		pressed_signal_name = value

		if not owner:
			return

		if not owner.has_signal(pressed_signal_name):
			push_warning("The owner doesn't have signal named: ", pressed_signal_name)

@export var font_size: int = 24:
	set(value):
		font_size = value
		$CenterContainer/Label.add_theme_font_size_override("font_size", font_size)

func _on_pressed() -> void:
	$AudioStreamPlayer.play()

func _on_audio_stream_player_finished() -> void:
	if not owner:
		push_error("No owner to call from!")
		return

	if owner.has_signal(pressed_signal_name):
		owner.emit_signal(pressed_signal_name)
	else:
		push_error("No signal bind to _on_pressed event")
