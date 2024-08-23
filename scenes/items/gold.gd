@icon("res://graphics/items/COINS.png")
extends Item

@export var gold: int = 1

func picked_up(player: Player):
	player.gold += gold
	super(player)
