@icon("res://graphics/items/armor.png")
extends Area2D

@export var speed_multiply:float=0.95
@export var armor_add:int=1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func picked_up(player:Player):
	player.defence += armor_add
	queue_free()

func _on_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	var area_as_player := area.owner as Player
	if area_as_player != null:
		picked_up(area_as_player)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
