extends CanvasLayer

#@export var player: Player = null#:
	#set(value):
		#if player:
			#await player.ready
		#player = value
		#%HealthBar.max_value = player.max_health
		#%HealthBar.set_value_no_signal(player.health)

@onready var health_bar: ProgressBar = $PlayerUserInterface/HealthBar
@onready var player_user_interface = $PlayerUserInterface
@onready var loading_screen = $LoadingScreen
@onready var score = %Score
@onready var speed = %Speed
@onready var defense = %Defense
@onready var attack = %Attack


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass


## Shows the loading screen if [param visibility] is [code]true[/code].
func show_loading_screen(visibility: bool) -> void:
	if visibility == true:
		player_user_interface.visible = false;
		loading_screen.visible = true;
	else:
		loading_screen.visible = false;
		player_user_interface.visible = true;

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


## Updates the on-screen buffs when they have changed.
func update_buff_ui(player: Player) -> void:
	score.text = "GLD: " + str(player.gold)
	attack.text = "ATK: " + str(player.attack_damage)
	defense.text = "DEF: " + str(player.defence)
	speed.text = "SPD: " + str(player.speed)


## Updates health progress bar value when player health changes.
func _on_player_health_changed(health: int) -> void:
	#print_debug("Health changed to: ", health)
	health_bar.value = health


## Updates health progress bar maximum value when player max health changes.
func _on_player_max_health_changed(max_health: int) -> void:
	#print_debug("Max health changed to: ", max_health)
	health_bar.max_value = max_health


## Handles [signal Player.buff_changed] and calls [function update_buff_ui].
func _on_player_buff_changed(player: Player) -> void:
	update_buff_ui(player)
