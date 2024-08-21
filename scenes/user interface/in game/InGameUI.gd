extends CanvasLayer

#@export var player: Player = null#:
	#set(value):
		#if player:
			#await player.ready
		#player = value
		#%HealthBar.max_value = player.max_health
		#%HealthBar.set_value_no_signal(player.health)

var character:Player
@onready var health_bar: ProgressBar = $PlayerUserInterface/HealthBar

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
	if character != null:
		$PlayerUserInterface/Score.text = "gold: " + str(character.gold)
		$PlayerUserInterface/Attack.text = "atk: " + str(character.attack_damage)
		$PlayerUserInterface/Defense.text = "def: " + str(character.defence)
		$PlayerUserInterface/Speed.text = "spd: " + str(character.speed)
		
	pass


## Updates health progress bar value when player health changes.
func _on_player_health_changed(health: int) -> void:
	#print_debug("Health changed to: ", health)
	health_bar.value = health

## Updates health progress bar maximum value when player max health changes.
func _on_player_max_health_changed(max_health: int) -> void:
	#print_debug("Max health changed to: ", max_health)
	health_bar.max_value = max_health
