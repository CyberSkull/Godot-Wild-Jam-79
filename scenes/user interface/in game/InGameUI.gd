extends CanvasLayer

@export var player: Player = null:
	set(value):
		if player:
			await player.ready
		player = value
		%HealthBar.max_value = player.max_health
		%HealthBar.set_value_no_signal(player.health)

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

## Shows the loading screen if [argument show] is [code]true[/code].
func show_loading_screen(show: bool) -> void:
	if show == true:
		$PlayerUserInterface.visible = false;
		$LoadingScreen.visible = true;
	else:
		$LoadingScreen.visible = false;
		$PlayerUserInterface.visible = true;

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if player:
		#%HealthBar.set_value_no_signal(player.health)
	pass


## Updates health progress bar value when player health changes.
func _on_player_health_changed(health: int) -> void:
	print_debug("Health changed to: ", health)
	%HealthBar.set_value_no_signal(health)

## Updates health progress bar maximum value when player max health changes.
func _on_player_max_health_changed(max_health: int) -> void:
	print_debug("Max health changed to: ", max_health)
	%HealthBar.max_value = max_health
