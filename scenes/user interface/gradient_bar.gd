extends ProgressBar


var my_style: StyleBoxFlat
@export var my_gradient: Gradient


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	my_style = get_theme_stylebox("fill").duplicate()
	add_theme_stylebox_override("fill", my_style)
	update_gradient()


## Updates the color of the health bar to [member Range.ratio].
func update_gradient() -> void:
	my_style.bg_color = my_gradient.sample(ratio)


## Handles [signal ProgressBar.changed] by calling [function update_gradient].
func _on_changed() -> void:
	update_gradient()


## Handles [signal ProgressBar.value_changed] by calling [function update_gradient].
func _on_value_changed(_value: float) -> void:
	update_gradient()
