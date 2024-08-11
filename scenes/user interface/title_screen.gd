extends Control


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



## Starts the game. TODO: implement.
func _on_start_game_button_pressed() -> void:
	OS.alert("Main game not implemented yet.")
	pass # Replace with function body.



## Pulls up the options screen. TODO: implement.
func _on_options_button_pressed() -> void:
	OS.alert("Options screen not implemented yet.")
	pass # Replace with function body.



## Quits the game.
func _on_quit_button_pressed() -> void:
	get_tree().quit()


