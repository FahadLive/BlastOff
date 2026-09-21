extends Control

signal main_menu_button_pressed

const ScoreItem = preload("ScoreItem.tscn")

@onready var score_list_node: VBoxContainer = $Panel/MarginContainer/Board/ScoreItemContainer
@onready var score_message_node: Label = $Panel/MarginContainer/Board/TextMessage

const NAME_CHANGE_COOLDOWN_TEXT = "Username can only be changed after 2 minutes"

var list_index := 0


# How many entries to display
@export var max_scores := 10

var _loading := false


func _ready() -> void:
	LeaderboardManager.triggered_leaderboard_reload.connect(_reload_data)
	LeaderboardManager.tried_new_display_name.connect(add_loading_scores_message)

	self.child_entered_tree.connect(_reload_data)
	self.main_menu_button_pressed.connect(_on_main_menu_button_pressed)

	_reload_data()


func _reload_data(_node = null) -> void:
	if _loading:
		return

	if LeaderboardManager.is_initializing:
		score_message_node.text = "Loading..."
		score_message_node.show()
		score_list_node.hide()
		await LeaderboardManager.initialization_finished

	if not LeaderboardManager.is_leaderboard_allowed:
		score_list_node.hide()
		score_message_node.text = """Leaderboard is disabled in this version.
Try reinstalling from itch.io"""
		score_message_node.show()
		return

	score_list_node.show()
	await _load_talo_leaderboard()


func _load_talo_leaderboard() -> void:
	_loading = true

	add_loading_scores_message()

	var res := await Talo.leaderboards.get_top_entries(LeaderboardManager.ld_name, max_scores)

	if not is_instance_valid(res):
		_loading = false
		add_no_scores_message()
		return

	var scores: Array = res.top_entries

	if scores.is_empty():
		_loading = false
		add_no_scores_message()
		return
	
	hide_message()
	render_board(scores)

	_loading = false


func render_board(scores: Array) -> void:
	clear_leaderboard()

	for entry in scores:
		var player_name = entry.player_alias.display_name
		# Fallback if display name is empty
		if player_name.is_empty():
			player_name = entry.player_alias.identifier

		add_item(
			player_name,
			str(int(entry.score))
		)


func add_item(player_name: String, score_value: String) -> void:
	var item = ScoreItem.instantiate()

	list_index += 1

	item.get_node("PlayerName").text = "%s. %s" % [
		list_index,
		player_name
	]

	item.get_node("Score").text = score_value

	item.offset_top = list_index * 100

	score_list_node.add_child(item)


func add_no_scores_message() -> void:
	score_message_node.text = "No scores yet!"
	score_message_node.show()
	score_list_node.hide()


func add_loading_scores_message(_signal_placeholder = null) -> void:
	score_message_node.text = "Loading scores..."
	score_message_node.show()
	score_list_node.hide()


func hide_message() -> void:
	score_message_node.hide()
	score_list_node.show()


func clear_leaderboard() -> void:
	list_index = 0

	for child in score_list_node.get_children():
		child.queue_free()


func _on_main_menu_button_pressed() -> void:
	UiManager.emit_signal("skipped_to_main_menu")
