@icon("res://icon/Dakota Duck.iconset/icon_16x16@2x.png")
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func start_game(new_seed:int):
	#$Level.player = $Player
	$Level.random = RandomNumberGenerator.new()
	$Level.random.seed = new_seed
	$InGameUI.character = $Player
	$Level.create_level(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_died() -> void:
	get_tree().change_scene_to_file("res://scenes/user interface/title_screen.tscn")
