@icon("res://icon/Dakota Duck.iconset/icon_16x16@2x.png")
extends Node2D

@onready var level = $Level


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func start_game(new_seed:int):
	#$Level.player = $Player
	level.random = RandomNumberGenerator.new()
	level.random.seed = new_seed
	level.create_level(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_player_died() -> void:
	get_tree().change_scene_to_file("res://scenes/user interface/title_screen.tscn")
