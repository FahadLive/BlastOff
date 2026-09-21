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
		var player_top_score: Dictionary ={}

		var top_score: Dictionary = player_top_score.get("top_score", {})

		if not top_score.is_empty():
			var sw_result: Dictionary = {}

			leaderboard_rank.text = str(sw_result.get("position", "-"))
		else:
			leaderboard_rank.text = "-"
		$"MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/Player Name".show()
		leaderboard_rank.show()
	else:
		$"MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/Player Name".hide()
		leaderboard_rank.hide()

func _on_back_button_pressed() -> void:
	UiManager.emit_signal("opened_start_menu")
