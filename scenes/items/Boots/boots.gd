@icon("res://graphics/items/Boots.png")
extends Item

@export var multiply_speed: float = 1.1

func picked_up(player: Player) -> void:
	var old_speed: float = player.speed
	player.speed *= multiply_speed
	message = str("+", snappedf(player.speed - old_speed, 3.1), " SPD")
	super(player)
