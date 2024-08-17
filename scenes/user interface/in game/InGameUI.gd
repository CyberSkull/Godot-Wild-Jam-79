extends CanvasLayer

var player:Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func show_loading_screen(show:bool):
	if show == true:
		$InGameUi.visible = false;
		$LoadingScreen.visible = true;
	else:
		$LoadingScreen.visible = false;
		$InGameUi.visible = true;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player == null:
		return
	$InGameUi/ProgressBar.set_value_no_signal(player.health)
	pass
