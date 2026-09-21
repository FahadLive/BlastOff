extends Control

signal back_button_pressed
signal refresh_ui(skin_type: int, is_initial_refresh: bool)

@onready var paint_cost_label: Button = $MarginContainer/VBoxContainer/TabContainer/Paint/VBoxContainer/HBoxContainer3/BuyButton/CenterContainer/MarginContainer/VBoxContainer/MarginContainer/PaintCost
@onready var sticker_cost_label: Button = $MarginContainer/VBoxContainer/TabContainer/Stickers/VBoxContainer/HBoxContainer3/BuyButton/CenterContainer/MarginContainer/VBoxContainer/MarginContainer/StickerCost

@onready var paint_buy_label: Label = $MarginContainer/VBoxContainer/TabContainer/Paint/VBoxContainer/HBoxContainer3/BuyButton/CenterContainer/MarginContainer/VBoxContainer/Label
@onready var sticker_buy_label: Label = $MarginContainer/VBoxContainer/TabContainer/Stickers/VBoxContainer/HBoxContainer3/BuyButton/CenterContainer/MarginContainer/VBoxContainer/Label


@onready var star_count_node: CenterContainer = $MarginContainer/VBoxContainer/HBoxContainer4/Control2/StarCount

@onready var paint_buy_button: TextureButton = $MarginContainer/VBoxContainer/TabContainer/Paint/VBoxContainer/HBoxContainer3/BuyButton
@onready var sticker_buy_button: TextureButton = $MarginContainer/VBoxContainer/TabContainer/Stickers/VBoxContainer/HBoxContainer3/BuyButton

@onready var sticker_applying_sound: AudioStreamPlayer = $MarginContainer/VBoxContainer/TabContainer/Stickers/ApplyStickerSound
@onready var repainitng_sound: AudioStreamPlayer = $MarginContainer/VBoxContainer/TabContainer/Paint/RepaintingSound
@onready var error_sound: AudioStreamPlayer = $ErrorSound

enum TABS {
	PAINT,
	STICKER,
}

var is_in_initial_setup:bool = true
var current_color_index: int # Useful for cycling through colors
var current_texture_index: int

var current_tab: int

func _ready() -> void:
	self.back_button_pressed.connect(_on_back_button_pressed)
	self.child_entered_tree.connect(_update_current_skin)
	self.refresh_ui.connect(_on_refresh)

	current_tab = $MarginContainer/VBoxContainer/TabContainer.current_tab

func _update_current_skin(_node: Node = null) -> void:
	current_color_index = SkinManager.available_color_ids.find(DataManager.gameplay.current_color)
	current_texture_index = SkinManager.available_texture_ids.find(DataManager.gameplay.current_texture)

	call_deferred("emit_signal", "refresh_ui", current_tab, true)

func _on_back_button_pressed() -> void:
	UiManager.emit_signal("opened_start_menu")

func _on_next_button_pressed(tab: int) -> void:
	_play_ui_sound()
	if tab == TABS.PAINT:
		current_color_index = (current_color_index + 1) % SkinManager.available_color_ids.size()

	elif tab == TABS.STICKER:
		current_texture_index = (current_texture_index + 1) % SkinManager.available_texture_ids.size()

	emit_signal("refresh_ui", tab)

func _on_previous_button_pressed(tab: int) -> void:
	_play_ui_sound()
	if tab == TABS.PAINT:
		current_color_index = (current_color_index - 1) % SkinManager.available_color_ids.size()

	elif tab == TABS.STICKER:
		current_texture_index = (current_texture_index - 1) % SkinManager.available_texture_ids.size()

	emit_signal("refresh_ui", tab)


func _on_buy_button_pressed(tab: int) -> void:
	var transaction_status: bool

	if tab == TABS.PAINT:
		var selected_paint_id: int = SkinManager.available_color_ids[current_color_index]
		transaction_status = _process_payment(selected_paint_id)

		if transaction_status:
			DataManager.gameplay.current_color = SkinManager.available_color_ids[current_color_index]
			SkinManager.emit_signal("bought_new_skin", SkinManager.SKIN_TYPES.PAINT)
			repainitng_sound.play()
		else:
			_indicate_insufficient_stars()

	elif tab == TABS.STICKER:
		var selected_sticker_id: int = SkinManager.available_texture_ids[current_texture_index]
		transaction_status = _process_payment(selected_sticker_id)

		if transaction_status:
			DataManager.gameplay.current_texture = SkinManager.available_texture_ids[current_texture_index]
			SkinManager.emit_signal("bought_new_skin", SkinManager.SKIN_TYPES.STICKER)
			sticker_applying_sound.play()
		else:
			_indicate_insufficient_stars()

	if transaction_status:
		self.emit_signal("refresh_ui", tab)
		DataManager.emit_signal("save_triggered")

func _process_payment(skin_id: int) -> bool:
	var current_star_count: int = DataManager.gameplay.total_stars

	var skin_cost: int = SkinManager.get_cost(skin_id)

	if skin_cost <= current_star_count:
		StatManager.emit_signal("star_count_changed", -1 * skin_cost)
		return true
	else:
		return false

func _indicate_insufficient_stars() -> void:
	error_sound.play()
	star_count_node.emit_signal("indicate_insufficiency")

func _on_refresh(skin_type: int, is_initial_refresh: bool = false) -> void:

	if is_in_initial_setup: # To prevent errors saying the child in not in tree
		if not self.is_node_ready():
			await self.ready
		is_in_initial_setup = false
	elif not is_initial_refresh: # To make sound, when changing tab and prevent simultaneous sound when entering from other menus
		_play_ui_sound()

	SkinManager.emit_signal("requested_skin_updation")

	if skin_type == TABS.PAINT:
		SkinManager.emit_signal("preview_color", SkinManager.get_color(SkinManager.available_color_ids[current_color_index]))
		paint_cost_label.text = str(SkinManager.get_cost(SkinManager.available_color_ids[current_color_index]))

		if _check_current_skin_applied(current_color_index, TABS.PAINT):
			paint_cost_label.hide()
			paint_buy_label.text = "Applied"
			paint_buy_button.disabled = true
		else:
			paint_buy_label.text = "Repaint"
			paint_cost_label.show()
			paint_buy_button.disabled = false

	elif skin_type == TABS.STICKER:
		SkinManager.emit_signal("preview_sticker", SkinManager.get_texture(SkinManager.available_texture_ids[current_texture_index]))
		sticker_cost_label.text = str(SkinManager.get_cost(SkinManager.available_texture_ids[current_texture_index]))

		if _check_current_skin_applied(current_texture_index, TABS.STICKER):
			sticker_buy_label.text = "Applied"
			sticker_cost_label.hide()
			sticker_buy_button.disabled = true
		else:
			sticker_buy_label.text = "Apply sticker"
			sticker_cost_label.show()
			sticker_buy_button.disabled = false

func _check_current_skin_applied(skin_index: int, skin_type: int) -> bool:
	match skin_type:
		TABS.PAINT:
			if DataManager.gameplay.current_color == SkinManager.available_color_ids[skin_index]:
				return true
			else:
				return false
		TABS.STICKER:
			if DataManager.gameplay.current_texture == SkinManager.available_texture_ids[current_texture_index]:
				return true
			else:
				return false

	return false ## If passed type is not on record

func _play_ui_sound():
	if $UISound.is_node_ready():
		$UISound.play()
