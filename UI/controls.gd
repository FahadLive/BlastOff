extends Control

enum {
	LEFT,
	RIGHT
}

func _ready() -> void:
	GameManager.game_over.connect(func (): get_parent().remove_child(self))

func switch_pressed_button(current_button: int) -> void:
	match current_button:
		LEFT:
			GameManager.is_left_button_pressed = true
			GameManager.is_right_button_pressed = false
		RIGHT:
			GameManager.is_right_button_pressed = true
			GameManager.is_left_button_pressed = false

func _turn_off_all_buttons() -> void:
	GameManager.is_right_button_pressed = false
	GameManager.is_left_button_pressed = false

func _input(event: InputEvent) -> void:
	GameManager.game_screen_size = get_viewport_rect().size
	var is_pressed_on_screen: bool = (event is InputEventScreenTouch and event.is_pressed()) or (event is InputEventScreenDrag)
	var is_released_from_screen: bool = event is InputEventScreenTouch and event.is_released()

	match UiManager.current_control_type:
		UiManager.CONTROL_TYPES.GUIDE:
			# Type - Guide: Set the button to the half of the screen where the player has pressed. ie, if pressed on the right side, right button is pressed
			if is_pressed_on_screen:

				if event.position.x > (GameManager.game_screen_size.x / 2):
					switch_pressed_button(RIGHT)
				else:
					switch_pressed_button(LEFT)
			elif is_released_from_screen: # Turning off the button where the player had recently pressed
				if event.position.x > (GameManager.game_screen_size.x / 2):
					GameManager.is_right_button_pressed = false
				else:
					GameManager.is_left_button_pressed = false

			else:
				_check_keyboard_input(event)


		UiManager.CONTROL_TYPES.FOLLOW:
			# Type - Follow: Determines with respect to the rocket, if pressed on the right side of the rocket, right button is pressed
			if is_pressed_on_screen:

				if not GameManager.rocket_has_reached_target.is_connected(_turn_off_all_buttons):
					GameManager.rocket_has_reached_target.connect(_turn_off_all_buttons)

				# Get event x position, compare it with rocket x position
				if event.position.x > GameManager.current_rocket_x_pos: # On the right side
					GameManager.emit_signal("ordered_rocket_to_target", event.position.x, UiManager.DIRECTIONS.RIGHT)
					switch_pressed_button(RIGHT)
				else:
					GameManager.emit_signal("ordered_rocket_to_target", event.position.x, UiManager.DIRECTIONS.LEFT)
					switch_pressed_button(LEFT)

			elif is_released_from_screen:
				if GameManager.rocket_has_reached_target.is_connected(_turn_off_all_buttons):
					GameManager.rocket_has_reached_target.disconnect(_turn_off_all_buttons)

				if event.position.x > GameManager.current_rocket_x_pos:
					GameManager.is_right_button_pressed = false
				else:
					GameManager.is_left_button_pressed = false

			else:
				_check_keyboard_input(event)

func _check_keyboard_input(input: InputEvent) -> void:
	if input.is_action_pressed("move_left"):
		switch_pressed_button(LEFT)
	elif input.is_action_pressed("move_right"):
		switch_pressed_button(RIGHT)
	elif input.is_action_released("move_left"):
		GameManager.is_left_button_pressed = false
	elif input.is_action_released("move_right"):
		GameManager.is_right_button_pressed = false
