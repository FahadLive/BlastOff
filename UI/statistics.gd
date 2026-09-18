extends Control

signal back_button_pressed

@onready var leaderboard_rank: Label = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer6/Rank
@onready var high_score_label: Label = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/HighScore
@onready var play_time_label: Label = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer3/PlayTime
@onready var stars_earned_label: Label = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer4/StarsEarnedCount
@onready var stars_spent_label: Label = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer5/StarsSpentCount


func _ready() -> void:
	self.back_button_pressed.connect(_on_back_button_pressed)
	self.child_entered_tree.connect(_refresh)

	_refresh()

func _refresh(_node: Node = null) -> void:
	high_score_label.text = str(DataManager.gameplay.high_score)
	play_time_label.text = str(roundi(DataManager.statistics.total_play_time)) + " sec"
	stars_earned_label.text = str(DataManager.statistics.total_stars_earned)
	stars_spent_label.text = str(DataManager.statistics.total_stars_spent)

	if LeaderboardManager.is_leaderboard_allowed:
		$"MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/Player Name".text = LeaderboardManager.current_display_name
		var player_top_score: Dictionary = await SilentWolf.Scores.get_top_score_by_player(LeaderboardManager.player_id).sw_top_player_score_complete
		var sw_result = await SilentWolf.Scores.get_score_position(player_top_score.top_score.score_id).sw_get_position_complete
		leaderboard_rank.text = str(sw_result.position)

		$"MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/Player Name".show()
		leaderboard_rank.show()
	else:
		$"MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/Player Name".hide()
		leaderboard_rank.hide()

func _on_back_button_pressed() -> void:
	UiManager.emit_signal("opened_start_menu")
