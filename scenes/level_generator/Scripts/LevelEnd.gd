extends Area2D

var random : RandomNumberGenerator
# Called when the node enters the scene tree for the first time.
func _ready():
	
	if random.randi_range(0,1):
		$LevelEnd.texture = preload("res://graphics/ladder/Ladder2.png")
	monitoring = true

func _on_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	var area_as_player := area.owner as Player
	if area_as_player != null:
		var level_gen :LevelGenerator= get_parent().get_parent()
		level_gen.end_level()

