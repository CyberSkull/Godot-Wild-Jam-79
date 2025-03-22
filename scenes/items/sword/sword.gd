@icon("res://graphics/items/SWORD.png")
extends Item

@export var damage_buff:int=1

func picked_up(player: Player, _message: String = "") -> void:
	player.attack_damage += damage_buff
	message = str("+", damage_buff, " DMG")
	super(player)
