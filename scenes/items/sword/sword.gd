@icon("res://graphics/items/SWORD.png")
extends Item

@export var damage_buff:int=1

func picked_up(player: Player) -> void:
	player.attack_damage += damage_buff
	super(player)
