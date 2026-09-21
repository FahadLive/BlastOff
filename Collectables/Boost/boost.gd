extends "res://Collectables/collectable.gd"

func _on_collection() -> void:
	PowerupManager.emit_signal("collected_powerup", collectable_type)
