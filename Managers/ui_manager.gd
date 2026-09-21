extends Node

signal warning_announced(x_position: float, warning_id: int) # For showing a warning sign when heavy objects are falling
signal warning_withdrawn(warning_id: int)

signal skipped_to_main_menu
signal opened_start_menu
signal opened_settings
signal opened_credits
signal opened_skin_selector
signal opened_statistics
signal opened_guide
signal opened_leaderboard

signal first_startup
signal show_basic_tutorial
signal show_powerup_tutorial

# For scene transition
signal show_transition ## Called when actual gameplay starts
signal entered_transition
signal remove_transition

signal triggered_gamearea_setup
signal triggered_menu_ui_setup ## Called when game is over --> This chains to GameManager.game_over

# Related to background.tscn
signal background_reload_requested
signal time_phase_changed(current_time_phase: int)

# For screen shake
signal triggered_screen_shake(shake_type: int)

enum TIME_PHASES {
	DAY,
	NIGHT
}

enum BACKGROUND_TYPES {
	RANDOM,
	TIME_BASED,
	DAY,
	NIGHT
}

enum CONTROL_TYPES {
	GUIDE,
	FOLLOW
}

enum DIRECTIONS {
	LEFT = -1,
	RESET,
	RIGHT
}

# Related to screen shake
enum STRENGTH_TYPES {
	HIGH,
	MED,
	LOW
}

const SHAKE_STRENGTHS = {
	STRENGTH_TYPES.HIGH: 0.5,
	STRENGTH_TYPES.MED: 0.25,
	STRENGTH_TYPES.LOW: 0.2
}

#MENU_LEVEL.MAIN is index 1 not zero so keep that in mind if you change to an array
enum MENU_IDS {
		NONE,
		MAIN_MENU,
		START_MENU,
		SETTINGS,
		CREDITS,
		CONTROLS,
		INGAME_UI,
		GAME_OVER,
		SKIN_SELECTOR,
		STATISTICS,
		GUIDE,
		LEADERBOARD
	}

var menus = {
	MENU_IDS.MAIN_MENU : preload("res://UI/main_menu.tscn").instantiate(),
	MENU_IDS.START_MENU: preload("res://UI/start_menu.tscn").instantiate(),
	MENU_IDS.SETTINGS : preload("res://UI/settings.tscn").instantiate(),
	MENU_IDS.CREDITS : preload("res://UI/credits.tscn").instantiate(),
	MENU_IDS.INGAME_UI : preload("res://UI/ingame_ui.tscn").instantiate(),
	MENU_IDS.GAME_OVER : preload("res://UI/game_over.tscn").instantiate(),
	MENU_IDS.CONTROLS: preload("res://UI/controls.tscn").instantiate(),
	MENU_IDS.SKIN_SELECTOR: preload("res://UI/skin_selector.tscn").instantiate(),
	MENU_IDS.STATISTICS: preload("res://UI/statistics.tscn").instantiate(),
	MENU_IDS.GUIDE: preload("res://UI/guide.tscn").instantiate(),
	MENU_IDS.LEADERBOARD: preload("res://UI/Leaderboard.tscn").instantiate(),
}

var need_basic_tutorial: bool = false
var need_powerup_tutorial: bool = false

var main_scene: Node
var current_menu: Node

var current_control_type: int = CONTROL_TYPES.GUIDE

var star_count_global_pos: Vector2 # To animate star collection

func _ready() -> void:
	self.first_startup.connect(func () -> void: need_basic_tutorial = true)
	GameManager.game_started.connect(_check_tutorial_need)
	DataManager.data_reloaded.connect(_reload_data)
	DataManager.data_got_changed.connect(_reload_data)

	self.skipped_to_main_menu.connect(spawn_menu.bind(MENU_IDS.MAIN_MENU))
	self.opened_start_menu.connect(spawn_menu.bind(MENU_IDS.START_MENU))
	self.opened_settings.connect(spawn_menu.bind(MENU_IDS.SETTINGS))
	self.opened_leaderboard.connect(spawn_menu.bind(MENU_IDS.LEADERBOARD))
	self.opened_credits.connect(spawn_menu.bind(MENU_IDS.CREDITS))
	self.opened_skin_selector.connect(spawn_menu.bind(MENU_IDS.SKIN_SELECTOR))
	self.opened_statistics.connect(spawn_menu.bind(MENU_IDS.STATISTICS))
	self.opened_guide.connect(spawn_menu.bind(MENU_IDS.GUIDE))

	self.triggered_gamearea_setup.connect(_spawn_ingame_uis)
	self.triggered_menu_ui_setup.connect(spawn_menu.bind(MENU_IDS.GAME_OVER))


func _reload_data() -> void:
	current_control_type = DataManager.settings.control_type

	if DataManager.statistics.powerups_used < 1 and not need_basic_tutorial:
		need_powerup_tutorial = true


func spawn_menu(menu_id: int):
	if menu_id == MENU_IDS.GAME_OVER:
		await _wait_till_transition()
		GameManager.emit_signal("game_over")
		self.emit_signal("remove_transition")

	call_deferred("_deferred_load_menu", menu_id)

func _spawn_ingame_uis():
	await _wait_till_transition()

	main_scene.add_child(menus[MENU_IDS.CONTROLS])
	spawn_menu(MENU_IDS.INGAME_UI)

	GameManager.call_deferred("emit_signal","game_started")

func _deferred_load_menu(menu_id: int):
	if not main_scene:
		push_error("Main scene not set in UiManager")
	#replace the current menus instance with the new ones
	current_menu = menus[menu_id]

	var menu_container = main_scene.find_child("Menu", false, false)

	if not menu_container:
		var menu_node = Node.new()
		menu_node.set_name("Menu")
		main_scene.add_child(menu_node)
		menu_container = menu_node

	#clear the current menu item/s
	for location in menu_container.get_children():
		menu_container.remove_child(location)

	#add our selected menu
	menu_container.add_child(current_menu)

	emit_signal("remove_transition")

func _check_tutorial_need() -> void:
	if need_basic_tutorial:
		emit_signal("show_basic_tutorial")
		need_basic_tutorial = false
	else:
		GameManager.emit_signal("start_spawning")

		if need_powerup_tutorial:
			emit_signal("show_powerup_tutorial")

func _wait_till_transition() -> void:
	emit_signal("show_transition")

	await self.entered_transition
