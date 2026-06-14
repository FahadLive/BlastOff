extends Control

signal back_button_pressed
signal credits_button_pressed

@onready var control_type_selector: OptionButton = $MarginContainer/WholeScreen/HBoxContainer/Sliders/ControlSelector
@onready var difficulty_level_selector: OptionButton = $MarginContainer/WholeScreen/HBoxContainer/Sliders/DifficultySelector
@onready var background_type_selector: OptionButton = $MarginContainer/WholeScreen/HBoxContainer/Sliders/BackgroundSelector

@onready var master_slider: HSlider = $MarginContainer/WholeScreen/HBoxContainer/Sliders/MasterSlide
@onready var music_slider: HSlider = $MarginContainer/WholeScreen/HBoxContainer/Sliders/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/WholeScreen/HBoxContainer/Sliders/SfxSlider
@onready var ui_slider: HSlider = $MarginContainer/WholeScreen/HBoxContainer/Sliders/UiSlider

@onready var button_pressed_sound = $ButtonSound

var volume_offset:float = 0

func _ready() -> void:
	self.back_button_pressed.connect(_on_back_button_pressed)
	self.credits_button_pressed.connect(_on_credits_button_pressed)

	master_slider.value = db_to_linear(SoundManager.get_bus_volume(SoundManager.MASTER)) + volume_offset
	music_slider.value = db_to_linear(SoundManager.get_bus_volume(SoundManager.MUSIC)) + volume_offset
	sfx_slider.value = db_to_linear(SoundManager.get_bus_volume(SoundManager.SFX)) + volume_offset
	ui_slider.value = db_to_linear(SoundManager.get_bus_volume(SoundManager.UI)) + volume_offset

	control_type_selector.selected = DataManager.settings.control_type
	difficulty_level_selector.selected = DataManager.gameplay.current_difficulty
	background_type_selector.selected = DataManager.settings.background_selection

func _on_back_button_pressed() -> void:
	DataManager.emit_signal("save_triggered")
	UiManager.emit_signal("skipped_to_main_menu")

func _on_credits_button_pressed() -> void:
	DataManager.emit_signal("save_triggered")
	UiManager.emit_signal("opened_credits")

func _on_master_slide_drag_ended(_value_changed: bool) -> void:
	_on_button_pressed()
	SoundManager.set_bus_volume(SoundManager.MASTER, linear_to_db(master_slider.value - volume_offset))

func _on_music_slider_drag_ended(_value_changed: bool) -> void:
	_on_button_pressed()
	SoundManager.set_bus_volume(SoundManager.MUSIC, linear_to_db(music_slider.value - volume_offset))

func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	_on_button_pressed()
	SoundManager.set_bus_volume(SoundManager.SFX, linear_to_db(sfx_slider.value - volume_offset))

func _on_ui_slider_drag_ended(_value_changed: bool) -> void:
	_on_button_pressed()
	SoundManager.set_bus_volume(SoundManager.UI, linear_to_db(ui_slider.value - volume_offset))

func _on_button_pressed() -> void:
	button_pressed_sound.play()

func _on_control_selector_item_selected(index: int) -> void: # Changing order in items of optionbutton will break this
	DataManager.settings.control_type = index
	DataManager.emit_signal("data_got_changed")

func _on_difficulty_selector_item_selected(index: int) -> void: # Changing order in items of optionbutton will break this
	DataManager.gameplay.current_difficulty = index
	GameManager.emit_signal("difficulty_level_changed", index)

func _on_background_selector_item_selected(index: int) -> void: # Hardcoded to map to UiManager.BACKGROUND_TYPES in the inspector (Changing order in items of optionbutton will break this)
	DataManager.settings.background_selection = index
	UiManager.emit_signal("background_reload_requested")
	DataManager.emit_signal("save_triggered")
