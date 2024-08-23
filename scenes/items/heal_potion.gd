@icon("res://graphics/items/healthpotion.png")
extends Item

@export var health_restored: int = 20

func picked_up(player: Player) -> void:
	player.health += health_restored
	super(player)
