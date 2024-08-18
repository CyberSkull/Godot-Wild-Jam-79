@icon("res://graphics/dungeon/Dungeon icon.png")
extends Node2D
class_name Level

@export var generator_scene: PackedScene
var generator: LevelGenerator

@export var player: Player = null

## TODO move this functionalty out of [Level] and into [Game].
@export var PlayerUI: CanvasLayer = null

var random: RandomNumberGenerator

var current_score: int

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	# TODO: add option to specify the seed in the begining of the game, or settings perhaps.
	#random = RandomNumberGenerator.new()
	# Make initial level.
	#$InGameUI.player = $Player
	#create_level(0)


## Creates the level.
func create_level(level_number: int):
	# TODO: show loading screen and then hide it later.
	if generator != null:
		generator.queue_free()
		generator = null;
	generator = generator_scene.instantiate()
	add_child(generator)
	generator.player_instance = player
	generator.generate(random, level_number) # later could make 
	PlayerUI.show_loading_screen(false)


