extends Control

# Create local signal for change to game scene
signal go_to_game

func _construct(mainNode):
	connect("go_to_game", mainNode, "_change_scene_to") # Connect callback for local signal

	$AnimationPlayerMenu.play("ModulateVariation") # Init main moon light animation

func _on_StartButton_pressed(): # Callback on click start button
	$CenterContainer/StartButton.modulate = Color(0.95, 0.95, 0.95, 1) # Change button light for response click

	emit_signal("go_to_game", "res://scenes/game/Map.tscn") # Emit signal to change scene

func _on_ExitButton_pressed(): # Callback on click start button
	get_tree().quit()
