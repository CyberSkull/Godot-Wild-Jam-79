@icon("res://graphics/items/Boots.png")
extends Item

@export var multiply_speed: float = 1.1

func picked_up(player: Player) -> void:
	player.speed *= multiply_speed
	super(player)
