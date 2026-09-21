extends Control

signal back_button_pressed

@onready var button_pressed_sound = $ButtonSound

func _ready() -> void:
	self.back_button_pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	UiManager.emit_signal("skipped_to_main_menu")

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
