extends Node

@export var water_level := -100.0

func _unhandled_input(event):
	if event is InputEventKey and event.is_released():
		if event.keycode == KEY_A:
			$boat.apply_impact_vector(Vector2(-1, 1))
		elif event.keycode == KEY_D:
			$boat.apply_impact_vector(Vector2(1, 1))
