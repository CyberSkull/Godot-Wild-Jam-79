extends Node2D
class_name Level

@export var generator_scene:PackedScene
var generator:LevelGenerator

var random:RandomNumberGenerator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#todo: add option to specify the seed in the begining of the game, or settings perhaps.
	random = RandomNumberGenerator.new()
	#make initial level.
	$InGameUi.player = $Player
	create_level(0)
	pass # Replace with function body.

func create_level(level_number : int):
	#todo: show loading screen and then hide it later.
	$InGameUi.show_loading_screen(false)
	if generator != null:
		generator.queue_free()
		generator = null;
	generator = generator_scene.instantiate()
	add_child(generator)
	generator.player_instance = $Player
	generator.generate(random, level_number)#later could make 


