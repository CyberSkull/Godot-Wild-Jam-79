extends CanvasLayer

## Speed in seconds that the [ProgressBar]'s [Tween].
@export var tween_speed: float = 0.25

@onready var health_bar: ProgressBar = %HealthBar
@onready var experience_bar: ProgressBar = %ExperienceBar
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
func update_stats_ui(player: Player) -> void:
	score.text = "GLD: " + str(player.gold)
	attack.text = "ATK: " + str(player.attack_damage)
	defense.text = "DEF: " + str(player.defence)
	speed.text = "SPD: " + str(snappedf(player.speed, 0.1))


## Updates health progress bar value when player health changes. Also has a [Tween] to animate the change in the health bar.
func _on_player_health_changed(health: int) -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(health_bar, "value", health, 0.25)
	tween.set_trans(Tween.TRANS_LINEAR)


## Updates health progress bar maximum value when player max health changes. Also fires a [Tween] to animate the change.
func _on_player_max_health_changed(max_health: int) -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(health_bar, "max_value", max_health, 0.25)
	tween.set_trans(Tween.TRANS_LINEAR)


## Handles [signal Player.buff_changed] and calls [function update_buff_ui].
func _on_player_buff_changed(player: Player) -> void:
	update_stats_ui(player)


## Handles a [signal Player.stats_changed] that updates the stats.
func _on_player_stats_changed(player: Player) -> void:
	update_stats_ui(player)
	

## Handles player experience gain.
func _on_player_gain_experience(experience_points, experience_to_next_level):
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(experience_bar, "value", experience_points, tween_speed)
	tween.tween_property(experience_bar, "max_value", experience_to_next_level, tween_speed)
	tween.set_trans(Tween.TRANS_LINEAR)
