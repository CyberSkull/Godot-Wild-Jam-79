@icon("res://graphics/items/COINS.png")
extends Item

@export var max_gold_in_pile: int = 100

## Called when the player enters the [CollisionShape2D]. Randomly gives the player between 1 and [member max_gold_in_pile] gold.
func picked_up(player: Player):
	var gold: int = randi_range(1, max_gold_in_pile)
	player.gold += gold
	message = str("+", gold, " GOLD")
	super(player)
