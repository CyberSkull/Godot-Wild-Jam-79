@icon("res://graphics/items/armor.png")
extends Item

@export var speed_multiply: float = 0.95
@export var armor_add: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func picked_up(player: Player):
	player.defence += armor_add
	super(player)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
