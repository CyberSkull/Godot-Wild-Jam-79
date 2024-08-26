extends ProgressBar

var health_style: StyleBoxFlat
@export var health_gradient: Gradient = preload("res://scenes/user interface/in game/health_gradient.tres")

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_style = get_theme_stylebox("fill").duplicate()
	add_theme_stylebox_override("fill", health_style)
	update_gradient()


## Updates the color of the health bar to [member Range.ratio].
func update_gradient() -> void:
	health_style.bg_color = health_gradient.sample(ratio)


## Handles [signal ProgressBar.changed] by calling [function update_gradient].
func _on_changed() -> void:
	update_gradient()


## Handles [signal ProgressBar.value_changed] by calling [function update_gradient].
func _on_value_changed(_value: float) -> void:
	update_gradient()
