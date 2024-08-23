extends Area2D

## List of possible textures for the end of the level ladder.
@export var textures: Array[Texture]

## A random number referenced outside this object.
var random: RandomNumberGenerator

## Called when the node enters the scene tree for the first time.
func _ready():
	$LevelEnd.texture = textures.pick_random()

## Goes to the next level when the player enters.
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var level_gen: LevelGenerator = get_parent().get_parent()
		level_gen.end_level()
