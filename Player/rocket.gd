extends Area2D

signal player_hurt

const MAX_SPEED: float = 100
const ACCELERATION: float = 70
const FRICTION = 90
const ROTATION_PER_FRAME = 50 # in degrees

enum FLAME_TYPES {
	NORMAL,
	BOOSTED
}

enum SHIELD_STAGES {
	ON,
	OFF
}

const SHIELD_TEXTURE: Texture2D = preload("res://Player/Powerups/rocket_shield.png")
const FLAME_GRADIENTS: Dictionary = {
	FLAME_TYPES.NORMAL: preload("res://Player/Gradients/normal_rocket_flame.tres"),
	FLAME_TYPES.BOOSTED: preload("res://Player/Gradients/boosted_rocket_flame.tres"),
}
const SHIELD_SFX: Dictionary = {
	SHIELD_STAGES.ON: preload("res://Player/Powerups/shield_on.wav"),
	SHIELD_STAGES.OFF: preload("res://Player/Powerups/shield_off.wav")
}

@onready var flame_particle_node: CPUParticles2D = $CPUParticles2D
@onready var rocket_collision_shape: CollisionShape2D = $CollisionShape2D

@onready var color_overlay_node: Sprite2D = $Sprite/Color
@onready var texture_overlay_node: Sprite2D = $Sprite/Texture
@onready var powerup_overlay_node: Sprite2D = $Sprite/Powerup

@onready var boost_audio_node: AudioStreamPlayer = $BoostToggleAudio
@onready var shield_audio_node: AudioStreamPlayer = $ShieldToggleAudio


var recently_collided_obstacles: Array[Node2D] = []

var is_game_running: bool = false
var is_free_falling: bool = false

var move_vec: Vector2
var last_sway_direction: int = UiManager.DIRECTIONS.RESET

var rotation_reset_tween: Tween
var faceplant_tween: Tween
var time_idle: float = 0

var initial_flame_speed: float
var half_of_rocket_width: float

# Variable to control rocket using FOLLOW control
var has_target_pos: bool
var target_x_pos: float
var targetted_side: int

# Variables related to powerups
var is_rocket_invincible: bool = false

var original_shield_scale: float = 0.3 # Should be changed everytime the shield is going to be expanded
var shield_scale_tween: Tween
var shield_ending_fade: Tween

var is_boost_active: bool = false
var rocket_speed_before_boost: float

func _reset_properties() -> void:
	_update_current_skin()
	self.show()
	$CollisionShape2D.disabled = false

	half_of_rocket_width = rocket_collision_shape.shape.radius + 5

	if faceplant_tween:
		faceplant_tween.stop()
		faceplant_tween.kill()

	move_vec = Vector2.ZERO
	is_free_falling = false
	self.rotation = 0
	var screen_size = get_viewport_rect().size

	self.position.x = screen_size.x / 2
	self.position.y = 0.8 * screen_size.y

	is_rocket_invincible = false
	$CPUParticles2D.color_ramp = FLAME_GRADIENTS.get(FLAME_TYPES.NORMAL)

func _ready() -> void:
	self.hide()
	GameManager.game_started.connect(_on_game_start)
	GameManager.game_over.connect(_on_game_over)

	GameManager.rocket_speed_changed.connect(_on_rocket_speed_changed)
	GameManager.ordered_rocket_to_target.connect(_set_target_pos)
	GameManager.rocket_has_reached_target.connect(_on_target_reached)

	PowerupManager.use_powerup.connect(_on_use_powerup)
	PowerupManager.stop_powerup.connect(_on_stop_powerup)

	self.player_hurt.connect(_on_hurt)

	initial_flame_speed = GameManager.rocket_speed

func apply_friction(velocity: float, delta: float) -> float:
	var magniitude_of_vec = abs(velocity)
	var direction_of_vec = (velocity / magniitude_of_vec) # Gives either 1 or -1 (left or right)
	magniitude_of_vec -= FRICTION * delta # Reduces the velocity

	if direction_of_vec == UiManager.DIRECTIONS.LEFT:
		sway(UiManager.DIRECTIONS.RIGHT, delta)
	else:
		sway(UiManager.DIRECTIONS.LEFT, delta)
	return (direction_of_vec * magniitude_of_vec)

func sway(sway_direction: int, delta: float) -> void:
	if not sway_direction in [-1, 0, 1]:
		push_error("Inputted a value other than -1 or 1")
		return
	if sway_direction != UiManager.DIRECTIONS.RESET:

		# if last rotation was opposite to current, set to zero then, sway to current side
		if last_sway_direction != sway_direction and self.rotation != 0:
			if not rotation_reset_tween or not rotation_reset_tween.is_running() :
				rotation_reset_tween = create_tween().set_parallel(true)
				rotation_reset_tween.tween_property(self, "rotation", 0, 0.1)
				rotation_reset_tween.tween_property(self, "skew", 0, 0.1)
		else:
			if rotation_reset_tween:
				rotation_reset_tween.stop()
				rotation_reset_tween.kill()

			last_sway_direction = sway_direction
			self.rotate(sway_direction * deg_to_rad(ROTATION_PER_FRAME * delta))

			var skew_amount: float = deg_to_rad(sway_direction * 8)
			self.skew = skew_amount
	else:
		if not rotation_reset_tween or not rotation_reset_tween.is_running() :
			rotation_reset_tween = create_tween().set_parallel(true)
			rotation_reset_tween.tween_property(self, "rotation", 0, 0.1)
			rotation_reset_tween.tween_property(self, "skew", 0, 0.1)

func _free_fall(delta) -> void:
	self.position.y += (GameManager.rocket_speed * delta)

func _set_target_pos(new_target_x_pos: float, taget_side: int):
	has_target_pos = true
	target_x_pos = new_target_x_pos
	targetted_side = taget_side

func move(delta: float):
	if is_free_falling:
		return

	# Increment velocity with ACCELERATION if given the input
	if GameManager.is_left_button_pressed or GameManager.is_right_button_pressed: # Checking whether either button is pressed
		if (GameManager.is_left_button_pressed and GameManager.is_right_button_pressed): # If both buttons are pressed, cancel it
			move_vec.x = apply_friction(move_vec.x, delta)
			time_idle += delta
		else:
			time_idle = 0

			if GameManager.is_left_button_pressed: # If asked to move left, accelerate to max speed
				move_vec.x += -1 * (ACCELERATION * delta) # Accelerate to -ve x
				sway(UiManager.DIRECTIONS.LEFT, delta)

			elif GameManager.is_right_button_pressed:
				move_vec.x += (ACCELERATION * delta)
				sway(UiManager.DIRECTIONS.RIGHT, delta)

	# Slowing down (gradually)
	elif move_vec.length() > (FRICTION * delta):
		time_idle += delta
		move_vec.x = apply_friction(move_vec.x, delta)
	else:
		time_idle += delta
		move_vec = Vector2.ZERO # Stop the character

	if time_idle > 0.2:
		sway(UiManager.DIRECTIONS.RESET, delta)

	move_vec = move_vec.limit_length(MAX_SPEED)
	self.position += move_vec

	# Preventing player from moving outside the screen
	var horizontal_screen_size = get_viewport_rect().size.x

	if (self.position.x >= horizontal_screen_size - half_of_rocket_width) or (self.position.x <= half_of_rocket_width):
		sway(UiManager.DIRECTIONS.RESET, delta)
		self.position.x = clamp(self.position.x , half_of_rocket_width, horizontal_screen_size - half_of_rocket_width) # Prevents the rocket from going off the screen
		move_vec = Vector2.ZERO # Resets the velocity to sudden stop

	GameManager.current_rocket_x_pos = self.position.x

	if has_target_pos:
		_check_if_passed_point(self.position.x, target_x_pos, targetted_side)

func _physics_process(delta: float) -> void:
	if is_game_running and not is_free_falling:
		move(delta)
	elif is_free_falling:
		_free_fall(delta) # When the rocket hits something

func _on_hurt():
	if is_free_falling: # The rocket has already has got the signal that its hurt
		return

	UiManager.emit_signal("triggered_menu_ui_setup")
	flame_particle_node.emitting = false
	is_free_falling = true

	if faceplant_tween:
		faceplant_tween.stop()
		faceplant_tween.kill()

	faceplant_tween = create_tween()
	faceplant_tween.tween_property(self, "rotation", deg_to_rad(180), 0.5)
	$CollisionShape2D.set_deferred("disabled", true)

func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:

	if not recently_collided_obstacles.has(area):
		recently_collided_obstacles.append(area)

		var removal_timer = get_tree().create_timer(0.5)
		removal_timer.timeout.connect(func (): recently_collided_obstacles.erase(area))

		if area.has_method("_on_hit"): # Calls the function present on the obstacle / collectable
			area.call("_on_hit")

		if area is Obstacle:
			if not is_rocket_invincible:
				emit_signal("player_hurt")
			else:
				if area.obstacle_type == SpawnManager.BIRD:
					PowerupManager.emit_signal("reduce_powerup_lifetime", 10)
				elif  area.obstacle_type == SpawnManager.SATELLITE:
					PowerupManager.emit_signal("reduce_powerup_lifetime", 50)
				_expand_shield() # Make the shield shine


func _on_game_start() -> void:
	_reset_properties()
	flame_particle_node.emitting = true
	is_game_running = true

func _on_game_over() -> void:
	flame_particle_node.emitting = false
	self.hide()

func _update_current_skin() -> void:
	color_overlay_node.texture = SkinManager.current_skin_textures.color
	texture_overlay_node.texture = SkinManager.current_skin_textures.texture

func _on_rocket_speed_changed(new_rocket_speed: float):
	flame_particle_node.speed_scale = new_rocket_speed / initial_flame_speed

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	self.hide()
	is_game_running = false

func _check_if_passed_point(current_x_pos: float, target_pos: float, target_side: int):
	match target_side:
		UiManager.DIRECTIONS.LEFT:
			if current_x_pos <= target_pos:
				GameManager.emit_signal("rocket_has_reached_target")

		UiManager.DIRECTIONS.RIGHT:
			if current_x_pos >= target_pos:
				GameManager.emit_signal("rocket_has_reached_target")

func _on_target_reached():
	has_target_pos = false

# Powerups Section

func _on_use_powerup(powerup_type: int):
	match powerup_type:
		SpawnManager.SHIELD:
			activate_shield()
			remove_boost()
		SpawnManager.BOOST:
			apply_boost()
			deactivate_shield()

func _on_stop_powerup():
	deactivate_shield()
	remove_boost()

func activate_shield() -> void:
	powerup_overlay_node.modulate = Color.WHITE

	if not is_rocket_invincible:
		shield_audio_node.stream = SHIELD_SFX.get(SHIELD_STAGES.ON)
		shield_audio_node.play()

	is_rocket_invincible = true
	powerup_overlay_node.texture = SHIELD_TEXTURE

	powerup_overlay_node.show()

func _expand_shield() -> void:
	powerup_overlay_node.scale = Vector2(original_shield_scale, original_shield_scale)
	const SCALE_TIME_PERIOD: float = .2

	var single_scale_lifetime: float = SCALE_TIME_PERIOD / 2
	var shrinking_scale = Vector2(original_shield_scale * 0.7, original_shield_scale * 0.7)

	if shield_scale_tween and shield_scale_tween.is_running():
		shield_scale_tween.stop()
		shield_scale_tween.kill()

	shield_scale_tween = create_tween().set_parallel(true)
	shield_scale_tween.tween_property(powerup_overlay_node, "scale", shrinking_scale, single_scale_lifetime)
	shield_scale_tween.tween_property(powerup_overlay_node, "scale", Vector2(original_shield_scale, original_shield_scale), single_scale_lifetime).set_delay(single_scale_lifetime)

func deactivate_shield() -> void:
	if is_rocket_invincible:
		shield_audio_node.stream = SHIELD_SFX.get(SHIELD_STAGES.OFF)
		shield_audio_node.play()

	powerup_overlay_node.hide()
	is_rocket_invincible = false

func apply_boost() -> void:
	if is_boost_active:
		return

	boost_audio_node.play()

	is_boost_active = true
	rocket_speed_before_boost = GameManager.rocket_speed

	GameManager.emit_signal("rocket_speed_changed", rocket_speed_before_boost * 1.5)
	$CPUParticles2D.color_ramp = FLAME_GRADIENTS.get(FLAME_TYPES.BOOSTED)

func remove_boost() -> void:
	if not is_boost_active:
		return

	boost_audio_node.play()

	is_boost_active = false
	$CPUParticles2D.color_ramp = FLAME_GRADIENTS.get(FLAME_TYPES.NORMAL)
	GameManager.emit_signal("rocket_speed_changed", rocket_speed_before_boost)
