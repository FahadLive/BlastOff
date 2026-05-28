extends Node

signal collected_powerup(powerup_type: int)
signal use_powerup(powerup_type: int)
signal stop_powerup
signal powerup_depleted
signal reduce_powerup_lifetime(reduction_percent: int) # Values from 0 to 100

enum POWERUP_STAGES {
    INACTIVE,
    UNUSED,
    IN_USE
}

const POWERUP_USAGE_RATE: Dictionary = { # as in percentage use per second
    POWERUP_STAGES.UNUSED: 2,
    POWERUP_STAGES.IN_USE: 15
}

var current_active_powerup: int
var current_powerup_stage: int = POWERUP_STAGES.UNUSED

var is_newly_collected_powerup_used: bool: # For statistical calculation (Determine no. of unique powerups used)
    set(value):
        if value == true:
            StatManager.emit_signal("used_unique_powerup")

        is_newly_collected_powerup_used = value

func _ready() -> void:
    GameManager.game_over.connect(func (): self.emit_signal("powerup_depleted"))

    self.collected_powerup.connect(_on_collected_powerup)
    self.use_powerup.connect(_on_use_powerup)
    self.stop_powerup.connect(_on_stop_powerup)
    self.powerup_depleted.connect(_on_powerup_depleted)

func _on_collected_powerup(collected_powerup_type: int) -> void:
    is_newly_collected_powerup_used = false

    if current_powerup_stage != POWERUP_STAGES.INACTIVE and collected_powerup_type != current_active_powerup:
        self.emit_signal("stop_powerup")

    current_powerup_stage = POWERUP_STAGES.UNUSED
    current_active_powerup = collected_powerup_type

func _on_use_powerup(_type: int):
    if not is_newly_collected_powerup_used:
        is_newly_collected_powerup_used = true
    current_powerup_stage = POWERUP_STAGES.IN_USE

func _on_stop_powerup():
    if current_powerup_stage != POWERUP_STAGES.INACTIVE:
        current_powerup_stage = POWERUP_STAGES.UNUSED

func _on_powerup_depleted() -> void:
    self.emit_signal("stop_powerup")
    current_powerup_stage = POWERUP_STAGES.INACTIVE
