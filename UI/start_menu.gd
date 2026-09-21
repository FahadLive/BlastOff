extends Control

signal change_skin_button_pressed
signal statistics_button_pressed
signal play_button_pressed
signal main_menu_button_pressed

@onready var color_overlay_node: TextureRect = $MarginContainer/VBoxContainer/VBoxContainer/RocketSkin/Color
@onready var texture_overlay_node: TextureRect = $MarginContainer/VBoxContainer/VBoxContainer/RocketSkin/Texture
@onready var name_label_node: Label = $MarginContainer/VBoxContainer/CenterContainer/DisplayNameContainer/HBoxContainer/Name
@onready var high_score_label: Label = $MarginContainer/VBoxContainer/CenterContainer/DisplayNameContainer/Score

@onready var name_changer_node: LineEdit = $MarginContainer/VBoxContainer/CenterContainer/DisplayNameContainer/NameChange/NameChanger
@onready var display_name_error: Label = $MarginContainer/VBoxContainer/CenterContainer/DisplayNameContainer/Tip
@onready var name_submit_button: TextureButton = $MarginContainer/VBoxContainer/CenterContainer/DisplayNameContainer/NameChange/CenterContainer/ChangeName
@onready var display_name_edit_container: BoxContainer = $MarginContainer/VBoxContainer/CenterContainer/DisplayNameContainer/NameChange
@onready var display_name_container: BoxContainer = $MarginContainer/VBoxContainer/CenterContainer/DisplayNameContainer/HBoxContainer

const NAME_CHANGE_COOLDOWN_TEXT = "Frequent name changes not allowed"

func _ready() -> void:
	self.play_button_pressed.connect(_on_play_button_pressed)
	self.statistics_button_pressed.connect(_on_statistics_button_pressed)
	self.main_menu_button_pressed.connect(_on_main_menu_button_pressed)
	self.change_skin_button_pressed.connect(_on_change_skin_button_pressed)
	
	LeaderboardManager.display_name_change_failed.connect(_on_display_name_error)
	LeaderboardManager.display_name_changed.connect(_on_refresh)

	self.child_entered_tree.connect(_on_refresh)
	_on_refresh()
	display_name_edit_container.hide()
	display_name_container.show()

func _on_play_button_pressed() -> void:
	UiManager.emit_signal("triggered_gamearea_setup")

func _on_statistics_button_pressed() -> void:
	UiManager.emit_signal("opened_statistics")

func _on_main_menu_button_pressed() -> void:
	UiManager.emit_signal("skipped_to_main_menu")

func _on_change_skin_button_pressed() -> void:
	UiManager.emit_signal("opened_skin_selector")

func _on_refresh(_node: Node = null) -> void:
	# The display name is loaded locally by LeaderboardManager on startup and
	# no longer depends on a live Talo connection, so it's always safe to
	# show here - don't gate it behind is_leaderboard_allowed, or it'll stay
	# hidden until (and unless) identification finishes over the network.
	name_label_node.text = LeaderboardManager.current_display_name
	name_label_node.show()
	high_score_label.text = "Score: " + str(int(DataManager.gameplay.high_score))
	_update_current_skin()

func _update_current_skin(_node: Node = null) -> void:
	color_overlay_node.texture = SkinManager.current_skin_textures.color
	texture_overlay_node.texture = SkinManager.current_skin_textures.texture

func _on_help_button_pressed() -> void:
	UiManager.emit_signal("opened_guide")

func _on_name_changer_text_changed(new_text: String) -> void:
	if display_name_error.is_visible_in_tree():
		display_name_error.hide()

func _on_change_name_pressed() -> void:
	if name_changer_node.text.is_empty():
		name_changer_node.text = LeaderboardManager.current_display_name

		display_name_error.text = "Name can't be empty"
		display_name_error.show()
		return

	name_submit_button.disabled = true

	$NameChangeTime.start()

	LeaderboardManager.emit_signal("tried_new_display_name", name_changer_node.text)
	name_label_node.text = LeaderboardManager.current_display_name
	display_name_edit_container.hide()
	display_name_container.show()

func _on_name_change_time_timeout() -> void:
	name_submit_button.disabled = false
	display_name_error.hide()

func _on_display_name_error(error_status: int):
	$NameChangeTime.stop()
	display_name_error.text = LeaderboardManager.DISPLAY_NAME_ERROR_MSGS.get(error_status)
	display_name_error.show()
	name_submit_button.disabled = false


func _on_name_edit_button_pressed() -> void:
	if not $NameChangeTime.is_stopped():
		display_name_error.text = NAME_CHANGE_COOLDOWN_TEXT
		display_name_error.show()
		$ErrorTimer.start()
		
		return
	
	display_name_container.hide()
	display_name_edit_container.show()


func _on_error_timer_timeout() -> void:
	display_name_error.hide()
