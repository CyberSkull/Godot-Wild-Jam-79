extends RichTextLabel
class_name FloatingText

@export var tween_duration: float = 1.0
@export var rise_height: int = -20

func _ready() -> void:
	#print_debug("Floating text: ", $RichTextLabel.text)
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "position:y", rise_height, tween_duration)
	tween.tween_callback(queue_free)
	#print_debug(tween)
