extends Control

@onready var left_tutorial: VBoxContainer = $VBoxContainer/HBoxContainer/MarginContainer/LeftTutorial
@onready var right_tutorial: VBoxContainer =$VBoxContainer/HBoxContainer/MarginContainer2/RightTutorial

@onready var control_tip_label: Label = $VBoxContainer/ControlTip
@onready var powerup_tip_label: Label = $VBoxContainer/PowerupTip
@onready var objective_label: Label = $VBoxContainer/Objective

var initial_rocket_speed: float # For accessing after tutorial is done

var is_basic_tutorial_finished: bool = true
var next_needed_input: int # Either left or right
var current_stage: int
var previous_stage: int = -1

enum {
	RIGHT,
	LEFT,
	GAME_START,
	POWERUP
}

func _ready() -> void:
	UiManager.show_basic_tutorial.connect(show_tutorial)
	UiManager.show_powerup_tutorial.connect(_on_show_powerup_tutorial)

	self.hide()
	left_tutorial.hide()
	right_tutorial.hide()
	objective_label.hide()
	$VBoxContainer/PowerupTip.hide()

	self.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_show_powerup_tutorial() -> void:
	self.show()
	current_stage = POWERUP
	_check_tutorial_status()

func show_tutorial() -> void:
	self.mouse_filter = Control.MOUSE_FILTER_PASS
	self.show()
	initial_rocket_speed = GameManager.rocket_speed
	GameManager.emit_signal("rocket_speed_changed", 100)
	current_stage = RIGHT # Initializing
	is_basic_tutorial_finished = false
	_check_tutorial_status()

func _check_tutorial_status() -> void:
		if previous_stage == current_stage:
			return

		match current_stage:
			RIGHT: # Shows right side instructions and wait for input
				right_tutorial.show()
				left_tutorial.hide()
				objective_label.hide()
			LEFT:
				left_tutorial.show()
				right_tutorial.hide()
				objective_label.hide()
			GAME_START: # Shows objective label and in the nxt step, make it fade
				objective_label.show()
				right_tutorial.hide()
				left_tutorial.hide()

				await get_tree().create_timer(3).timeout

				control_tip_label.show()
				get_tree().create_timer(1.5).timeout.connect(func (): control_tip_label.hide())

				is_basic_tutorial_finished = true
				_on_basic_tutorial_finished()
			POWERUP:
				await PowerupManager.collected_powerup
				powerup_tip_label.show()

				GameManager.game_over.connect(func (): powerup_tip_label.hide()) # Fallback - Not the ideal solution

				await PowerupManager.use_powerup
				powerup_tip_label.hide()
				UiManager.need_powerup_tutorial = false

				self.hide()
			_:
				previous_stage = current_stage

func _physics_process(_delta: float) -> void:
	if not is_basic_tutorial_finished:
		if GameManager.is_right_button_pressed and current_stage == RIGHT:
			current_stage = LEFT
			_check_tutorial_status()
		elif GameManager.is_left_button_pressed and current_stage == LEFT:
			current_stage = GAME_START
			_check_tutorial_status()

func _on_basic_tutorial_finished() -> void:
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.emit_signal("rocket_speed_changed", initial_rocket_speed)
	GameManager.emit_signal("start_spawning")
	objective_label.hide()

	current_stage = POWERUP
	_check_tutorial_status()
