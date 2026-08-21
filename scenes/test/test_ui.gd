extends Control


func _on_button_pressed() -> void:
	var new_position = Vector2(0, 0)
	GameEvents.grave_opened.emit(new_position, 1)
