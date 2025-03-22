@icon("res://graphics/items/healthpotion.png")
extends Item

@export var health_restored: int = 20

## Pick up potion if [Player] is not at full health. 
func picked_up(player: Player, _message: String = "") -> void:
	if player.health < player.max_health:
		player.health += health_restored
		message = str("+", health_restored, " HP")
		super(player)
