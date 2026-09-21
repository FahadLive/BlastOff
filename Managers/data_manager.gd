extends Node

signal save_triggered # Triggered from settings and when game is over (Here)
signal reload_triggered

signal data_got_changed

signal data_reloaded
# All items here are synced across sessions

const SAVE_FILE_NAME: String = "user://blastoff_data.cfg"

## Gameplay
var gameplay: Dictionary = {
	high_score = 0,
	total_stars = 0,
	current_texture = 10,
	current_color = 100,
	current_difficulty = GameManager.DIFFICULTY_LEVELS.EASY
}

## settings
var settings: Dictionary = {
	display_name = "",
	bus_volumes = {}, # Bus volume mapped to their id value is decibels
	control_type = UiManager.CONTROL_TYPES.GUIDE,
	background_selection = UiManager.BACKGROUND_TYPES.RANDOM
}

## Statistics
var statistics: Dictionary = {
	total_play_time = 0,
	total_stars_earned = 0,
	total_stars_spent = 0,
	powerups_used = 0
}


var is_initialisation_complete: bool = false

func _ready() -> void:
	self.save_triggered.connect(save_to_files)
	self.reload_triggered.connect(load_from_files)

	self.data_reloaded.connect(_on_data_reloaded)
	load_from_files()

	GameManager.game_over.connect(func (): self.emit_signal("save_triggered"))

func _on_data_reloaded() -> void:
	is_initialisation_complete = true

func save_to_files() -> void:
	SoundManager._report_bus_volumes()
	var new_file = ConfigFile.new()

	for each_key in gameplay:
		new_file.set_value("gameplay", each_key, gameplay[each_key])

	for each_key in settings:
		new_file.set_value("settings", each_key, settings[each_key])

	for each_key in statistics:
		new_file.set_value("statistics", each_key, statistics[each_key])


	new_file.save(SAVE_FILE_NAME)

func load_from_files() -> void:
	var saved_file: ConfigFile = ConfigFile.new()

	var load_status = saved_file.load(SAVE_FILE_NAME)

	if load_status != OK: # No save file, treating as if the game is started for the first time
		UiManager.emit_signal("first_startup")
		emit_signal("data_reloaded")
		return

	for each_section in saved_file.get_sections():
		match each_section:
			"gameplay":
				var loaded_gameplay_data = _load_data_to_dictionary(saved_file, each_section) # Overwrites all the data in dictionary
				gameplay = _check_for_data_updation(gameplay, loaded_gameplay_data)
			"settings":
				var loaded_settings_data = _load_data_to_dictionary(saved_file, each_section)
				settings = _check_for_data_updation(settings, loaded_settings_data)
			"statistics":
				var loaded_statistics_data = _load_data_to_dictionary(saved_file, each_section)
				statistics = _check_for_data_updation(statistics, loaded_statistics_data)
	emit_signal("data_reloaded")


func _load_data_to_dictionary(save_file: ConfigFile, section_name: String) -> Dictionary:
	var target_dict: Dictionary = {}
	for each_key in save_file.get_section_keys(section_name):
		target_dict[each_key] = save_file.get_value(section_name, each_key)

	return target_dict

func _check_for_data_updation(default_dict: Dictionary, newly_loaded_dict: Dictionary = {}) ->  Dictionary: ## This fn. checks whether the newly loaded dictionary contains all the entries of latest update, if add them with their default value
	var updated_dict: Dictionary = {}

	var keys_in_loaded_data: Array = newly_loaded_dict.keys()
	var keys_in_default_dict: Array = default_dict.keys()

	for each_key in keys_in_default_dict:
		if keys_in_loaded_data.has(each_key):
			updated_dict[each_key] = newly_loaded_dict.get(each_key)
		else:
			updated_dict[each_key] = default_dict.get(each_key)

	return updated_dict
