extends CanvasLayer

@onready var simultaneous_scene = preload("res://scenes/game/game.tscn").instantiate()
@onready var title_screen_seed = %Seed


## Generates a random integer for the game seed.
func new_random_seed()->void:
	title_screen_seed.text = str(randi())


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%StartGameButton.grab_focus()
	new_random_seed()



## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Starts the game.
func _on_start_game_button_pressed() -> void:
	var world_seed = int(title_screen_seed.text)

	# This is like autoloading the scene, only
	# it happens after already loading the main scene.
	get_tree().root.add_child(simultaneous_scene)
	simultaneous_scene.start_game(world_seed)
	queue_free()



## Pulls up the options screen. TODO: implement.
func _on_options_button_pressed() -> void:
	OS.alert("Options screen not implemented yet. ☹️", "Unimplemented function!")
	pass # Replace with function body.



## Quits the game.
func _on_quit_button_pressed() -> void:
	get_tree().quit()
