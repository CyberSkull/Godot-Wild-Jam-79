class_name Item
extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

## Frees the item. Should be overrided by a child class to invoke the item effect, then called with [code]super(player)[/code].
func picked_up(_player: Player):
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		picked_up(body as Player)
