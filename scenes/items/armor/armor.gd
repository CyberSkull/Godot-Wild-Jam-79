@icon("res://graphics/items/armor.png")
extends Item

@export var speed_multiply: float = 0.95
@export var armor_add: int = 1

func picked_up(player: Player):
	player.defence += armor_add
	message = str("+", armor_add, " DEF")
	super(player)
