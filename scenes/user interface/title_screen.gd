extends CanvasLayer

func new_random_seed()->void:
	$MarginContainer/VBoxContainer/HBoxContainer/TextEdit.text = str(randi())
## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_random_seed()
	pass # Replace with function body.



## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

var simultaneous_scene:Level = preload("res://scenes/level_generator/Level.tscn").instantiate()

## Starts the game. TODO: implement.
func _on_start_game_button_pressed() -> void:
	var seed = int($MarginContainer/VBoxContainer/HBoxContainer/TextEdit.text)

	# This is like autoloading the scene, only
	# it happens after already loading the main scene.
	get_tree().root.add_child(simultaneous_scene)
	simultaneous_scene.random.seed = seed
	simultaneous_scene.create_level(0)
	queue_free()
	#OS.alert("Main game not implemented yet. ☹️", "Unimplemented function!")
	pass # Replace with function body.



## Pulls up the options screen. TODO: implement.
func _on_options_button_pressed() -> void:
	OS.alert("Options screen not implemented yet. ☹️", "Unimplemented function!")
	pass # Replace with function body.



## Quits the game.
func _on_quit_button_pressed() -> void:
	get_tree().quit()


