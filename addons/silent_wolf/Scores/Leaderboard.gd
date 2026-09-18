extends Control

const ScoreItem = preload("ScoreItem.tscn")
const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")

@onready var score_list_node: VBoxContainer = $Panel/MarginContainer/Board/ScoreItemContainer
@onready var score_message_node: Label = $Panel/MarginContainer/Board/TextMessage
@onready var name_changer_node: LineEdit = $Panel/MarginContainer/Board/CenterContainer/DisplayNameContainer/HBoxContainer/NameChanger
@onready var display_name_error: Label = $Panel/MarginContainer/Board/CenterContainer/DisplayNameContainer/Tip
@onready var display_name_container: BoxContainer = $Panel/MarginContainer/Board/CenterContainer/DisplayNameContainer
@onready var name_submit_button: Button = $Panel/MarginContainer/Board/CenterContainer/DisplayNameContainer/HBoxContainer/CenterContainer/ChangeName

const NAME_CHANGE_COOLDOWN_TEXT = "Username can only be changed after 2 minutes"

var list_index = 0
# Replace the leaderboard name if you're not using the default leaderboard
var ld_name = "main"
var max_scores = 10


func _ready():

	LeaderboardManager.triggered_leaderboard_reload.connect(_reload_data)

	LeaderboardManager.tried_new_display_name.connect(add_loading_scores_message)
	LeaderboardManager.display_name_change_failed.connect(_on_display_name_error)

	self.child_entered_tree.connect(_reload_data)

	_reload_data()

func _reload_data(_node = null) -> void:
	if not LeaderboardManager.is_leaderboard_allowed:
		display_name_container.hide()
		score_list_node.hide()
		score_message_node.text = "Leaderboard is disabled in this version
        Try reinstalling from itch.io"

		return
	else:
		display_name_container.show()
		score_list_node.show()

	name_changer_node.max_length = LeaderboardManager.MAX_NAME_LENGTH
	name_changer_node.text = LeaderboardManager.current_display_name

	print("SilentWolf.Scores.leaderboards: " + str(SilentWolf.Scores.leaderboards))
	print("SilentWolf.Scores.ldboard_config: " + str(SilentWolf.Scores.ldboard_config))
	var scores = SilentWolf.Scores.scores

	if ld_name in SilentWolf.Scores.leaderboards:
		scores = SilentWolf.Scores.leaderboards[ld_name]
	var local_scores = SilentWolf.Scores.local_scores

	## use a signal to notify when the high scores have been returned, and show a "loading" animation until it's the case...
	add_loading_scores_message()
	var sw_result = await SilentWolf.Scores.get_scores().sw_get_scores_complete
	scores = sw_result.scores
	hide_message()
	render_board(scores, local_scores)


func render_board(scores: Array, local_scores: Array) -> void:
	clear_leaderboard()

	if ld_name in SilentWolf.Scores.ldboard_config and is_default_leaderboard(SilentWolf.Scores.ldboard_config[ld_name]):
		if scores.is_empty():
			add_no_scores_message()
	else:
		if scores.is_empty():
			add_no_scores_message()
	if scores.is_empty():
		for score in scores:
			if score.has("metadata") and score.metadata.has("display_name"):
				add_item(score.metadata.display_name, str(int(score.score)))
			else:
				add_item(score.player_name, str(int(score.score)))
	else:
		for score in scores:
			if score.has("metadata") and score.metadata.has("display_name"):
				add_item(score.metadata.display_name, str(int(score.score)))
			else:
				add_item(score.player_name, str(int(score.score)))


func is_default_leaderboard(ld_config: Dictionary) -> bool:
	var default_insert_opt = (ld_config.insert_opt == "keep")
	var not_time_based = !("time_based" in ld_config)
	return default_insert_opt and not_time_based


func merge_scores_with_local_scores(scores: Array, local_scores: Array, max_scores: int=10) -> Array:
	if local_scores:
		for score in local_scores:
			var in_array = score_in_score_array(scores, score)
			if !in_array:
				scores.append(score)
			scores.sort_custom(sort_by_score);
	if scores.size() > max_scores:
		var new_size = scores.resize(max_scores)
	return scores


func sort_by_score(a: Dictionary, b: Dictionary) -> bool:
	if a.score > b.score:
		return true;
	else:
		if a.score < b.score:
			return false;
		else:
			return true;


func score_in_score_array(scores: Array, new_score: Dictionary) -> bool:
	var in_score_array =  false
	if !new_score.is_empty() and !scores.is_empty():
		for score in scores:
			if score.score_id == new_score.score_id: # score.player_name == new_score.player_name and score.score == new_score.score:
				in_score_array = true
	return in_score_array


func add_item(player_name: String, score_value: String) -> void:
	var item = ScoreItem.instantiate()
	list_index += 1
	item.get_node("PlayerName").text = str(list_index) + str(". ") + player_name
	item.get_node("Score").text = score_value
	item.offset_top = list_index * 100
	score_list_node.add_child(item)


func add_no_scores_message() -> void:
	var item = score_message_node
	item.text = "No scores yet!"
	score_message_node.show()
	item.offset_top = 135


func add_loading_scores_message(_signal_placeholder = null) -> void:
	var item = score_message_node
	item.text = "Loading scores..."
	score_message_node.show()
	score_list_node.hide()
	#item.offset_top = 135

func hide_message() -> void:
	score_message_node.hide()
	score_list_node.show()

func clear_leaderboard() -> void:
	list_index = 0
	if score_list_node.get_child_count() > 0:
		var children = score_list_node.get_children()
		for c in children:
			score_list_node.remove_child(c)
			c.queue_free()

func _on_change_name_pressed() -> void:
	if name_changer_node.text.is_empty():
		name_changer_node.text = LeaderboardManager.current_display_name

		display_name_error.text = "Name can't be empty"
		display_name_error.show()
		return

	name_submit_button.disabled = true

	$NameChangeTime.start()

	display_name_error.text = NAME_CHANGE_COOLDOWN_TEXT
	display_name_error.show()
	LeaderboardManager.emit_signal("tried_new_display_name", name_changer_node.text)

func _on_display_name_error(error_status: int):
	hide_message()

	$NameChangeTime.stop()
	display_name_error.text = LeaderboardManager.DISPLAY_NAME_ERROR_MSGS.get(error_status)
	display_name_error.show()
	name_submit_button.disabled = false

func _on_name_change_time_timeout() -> void:
	name_submit_button.disabled = false
	display_name_error.hide()

func _on_line_edit_text_changed(new_text: String) -> void:
	if display_name_error.is_visible_in_tree():
		display_name_error.hide()
