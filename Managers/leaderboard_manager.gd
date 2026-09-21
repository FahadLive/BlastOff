extends Node

signal triggered_leaderboard_reload
signal display_name_changed(new_name: String)
signal tried_new_display_name(new_name: String)
signal display_name_change_failed(error_code: int)
signal initialization_finished

enum DISPLAY_NAME_ERRORS {
	NONE,
	HAS_SPACE,
	TOO_LONG,
	HAS_SPECIAL_CHARS,
	HAS_EXPLICIT_WORDS,
}

const DISPLAY_NAME_ERROR_MSGS = {
	DISPLAY_NAME_ERRORS.HAS_SPACE : "Name should not contains spaces",
	DISPLAY_NAME_ERRORS.TOO_LONG : "Name is too long, try reducing number of letters",
	DISPLAY_NAME_ERRORS.HAS_SPECIAL_CHARS : "Name can't have special characters (%, _, #, etc. )",
	DISPLAY_NAME_ERRORS.HAS_EXPLICIT_WORDS : "Name can't have explicit words, try another name",
}

const PATH_TO_FILTER_WORD_FILE = "res://Data/bad_words_filter.txt"

const MAX_NAME_LENGTH: int = 8

# The leaderboard's "Internal name" as set on the Talo dashboard.
# ScoreBoard.gd reads this via LeaderboardManager.ld_name.
const ld_name: String = "blastoff-dev"

# The prop key used to store a player's chosen display name. This must match
# the "display name prop key" configured on the Talo dashboard's Game
# Settings page, otherwise entries will show the raw device identifier
# instead of the name the player picked.
const DISPLAY_NAME_PROP_KEY: String = "display_name"

# Reserved word "Talo" can't be used here - it's reserved for Talo Player
# Authentication, so we identify with a plain device-based service instead.
const IDENTIFY_SERVICE: String = "device"

var is_leaderboard_allowed: bool = false
var is_initializing: bool = true

var current_display_name: String = OS.get_unique_id()

var offensive_filter_words: PackedStringArray = []


func _ready() -> void:
	offensive_filter_words = _setup_filter_word_list()

	StatManager.new_high_score_gained.connect(_add_player_high_score)
	self.tried_new_display_name.connect(_process_new_display_name)

	# Load and broadcast the locally-saved display name right away. Don't
	# make UI wait on a Talo network round trip just to know the player's
	# own name - that's what caused it to show blank/stale initially.
	await _setup_local_displayname()

	# Identification and leaderboard I/O are network-bound; run them after,
	# in the background, without blocking anything that only needs the name.
	_setup_talo()


func _setup_local_displayname() -> void:
	if not DataManager.is_initialisation_complete:
		await DataManager.data_reloaded

	var saved_display_name: String = DataManager.settings.display_name

	if saved_display_name.is_empty(): # Sets player id as display name
		DataManager.settings.display_name = current_display_name
	else:
		current_display_name = saved_display_name

	emit_signal("display_name_changed", current_display_name)


func _setup_talo() -> void:
	# Talo's autoload sets up Talo.players in its own _ready(). If this
	# autoload runs first (wrong order in Project Settings > Autoload, or a
	# one-frame race), Talo.players can still be null here - wait a frame
	# and retry rather than crashing.
	while not is_instance_valid(Talo) or Talo.players == null:
		await get_tree().process_frame

	Talo.players.identification_failed.connect(_on_identification_failed)

	# access_key / api_url are configured in addons/talo/settings.cfg, not here.
	await Talo.players.identify(IDENTIFY_SERVICE, OS.get_unique_id())

	is_initializing = false

	if Talo.current_player == null:
		is_leaderboard_allowed = false
		emit_signal("initialization_finished")
		return

	is_leaderboard_allowed = true

	await Talo.current_player.set_prop(DISPLAY_NAME_PROP_KEY, current_display_name)
	emit_signal("initialization_finished")
	await _process_high_score()


func _process_high_score(is_updating_display_name: bool = false) -> void:
	if not DataManager.is_initialisation_complete:
		await DataManager.data_reloaded

	# Talo leaderboards configured as "unique" on the dashboard automatically
	# keep only a player's best entry, so there's no need to manually delete
	# older/duplicate entries here like the SilentWolf version did.
	var options := Talo.leaderboards.GetEntriesOptions.new()
	options.player_id = Talo.current_player.id

	var res := await Talo.leaderboards.get_entries(ld_name, options)

	var has_remote_score: bool = res != null and res.entries.size() > 0
	var remote_high_score: int = int(res.entries[0].score) if has_remote_score else 0

	if not is_updating_display_name:
		# Checking it with local saved score, and keeping the highest one
		if not has_remote_score or DataManager.gameplay.high_score > remote_high_score:
			_replace_high_score(DataManager.gameplay.high_score)
		else:
			DataManager.gameplay.high_score = remote_high_score
			DataManager.emit_signal("save_triggered")

	emit_signal("triggered_leaderboard_reload")


func _replace_high_score(new_high_score: int, is_updating_display_name: bool = false) -> void:
	await Talo.leaderboards.add_entry(ld_name, new_high_score)
	_process_high_score(is_updating_display_name)


func _add_player_high_score(new_high_score: int, is_updating_display_name: bool = false) -> void:
	if is_leaderboard_allowed:
		_replace_high_score(new_high_score, is_updating_display_name)


func _setup_filter_word_list() -> PackedStringArray:
	var txt_file = FileAccess.open(PATH_TO_FILTER_WORD_FILE, FileAccess.READ)
	var file_content: String = txt_file.get_as_text()

	return file_content.split("\n")


func _process_new_display_name(new_name: String) -> void:
	var word_status = _filter_word(new_name)

	if word_status != DISPLAY_NAME_ERRORS.NONE:
		emit_signal("display_name_change_failed", word_status)
		return

	if new_name == DataManager.settings.display_name:
		return

	DataManager.settings.display_name = new_name
	current_display_name = new_name

	DataManager.emit_signal("save_triggered")

	if is_leaderboard_allowed:
		var result = await Talo.current_player.set_prop(DISPLAY_NAME_PROP_KEY, new_name)

		if result.rejected_props.size() > 0:
			# Talo's own profanity/length checks caught something our local filter missed
			emit_signal("display_name_change_failed", DISPLAY_NAME_ERRORS.HAS_EXPLICIT_WORDS)
			return

		_add_player_high_score(DataManager.gameplay.high_score, true) # To trigger save, with new metadata


func _on_identification_failed(error) -> void:
	is_leaderboard_allowed = false
	push_warning("Talo identification failed: %s" % error.code)


func _filter_word(word_to_filter: String) -> int:
	word_to_filter = word_to_filter.trim_suffix(" ").trim_prefix(" ")
	var current_status: int = DISPLAY_NAME_ERRORS.NONE

	var special_char_regex: RegEx = RegEx.new()
	special_char_regex.compile("[@_!#$%^&*()<>?/|}{~:]")

	# Check if its a single word (can't have spaces)
	if word_to_filter.contains(" "):
		current_status = DISPLAY_NAME_ERRORS.HAS_SPACE
	# Limit length to 8 letters
	if word_to_filter.length() > MAX_NAME_LENGTH:
		current_status = DISPLAY_NAME_ERRORS.TOO_LONG
	# No _ or -, or any other special letters
	if special_char_regex.search(word_to_filter):
		current_status = DISPLAY_NAME_ERRORS.HAS_SPECIAL_CHARS
	# No offensive wording
	if offensive_filter_words.has(word_to_filter):
		current_status = DISPLAY_NAME_ERRORS.HAS_EXPLICIT_WORDS

	return current_status
