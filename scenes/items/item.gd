class_name Item
extends Area2D

var _floating_text_scene: PackedScene = preload("res://scenes/user interface/floating_text.tscn")


## [Color] of the message
@export_color_no_alpha var message_color: Color = Color.WHITE

## Message to print when item picked up.
var message: String = ""



## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## Frees the item. Should be overrided by child classes to invoke the item effect, then called with [code]super(player)[/code] at the end of the overriding method.
func picked_up(player: Player):
	if message != "":
		var floating_text: RichTextLabel = _floating_text_scene.instantiate()
		floating_text.push_color(message_color)
		floating_text.append_text(message)
		floating_text.pop() #Closes color tag.
		player.add_child(floating_text) 
	queue_free()


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Handles a [Player] entering the [Item] area. Calls [method picked_up].
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		picked_up(body as Player)
