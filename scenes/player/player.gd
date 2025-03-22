@icon("res://graphics/Dakota Duck/Dakota Duck icon.png")
## Class for the [Player] character.
class_name Player
extends CharacterBody2D

## Emitted when the [Player] gains or looses [member health] or [member max_health].
signal health_changed(health: int)
## Emitted when the [Player] gains or looses [member health] or [member max_health].
signal max_health_changed(max_health: int)
## Emitted when a stat changes.
signal stats_changed(player: Player)
## Emitted when the player gains experience points.
signal gain_experience(experience_points: int, experience_to_next_level: int)
## Emitted when [member Attack Damage] changes.
#signal attack_changed(attack: int)
## Emitted when the [Player] dies. Triggers game over.
signal died()
## Emitted when the player levels up.
signal leveled_up(level: int)

## Gold carried by player.
var gold: int = 0:
	set(value):
		gold = value
		stats_changed.emit(self)

@export_category("Stats")
## Maximum [Player] health. Emits [signal health_changed] when changed.
@export var max_health: int = 100:
	set(value):
		max_health = value
		max_health_changed.emit(max_health)


## Current [Player] health. Clamped to [member max_health]. Emits [signal health_changed] when changed. Emits [signal died] when <= 0.
@export var health: int = 100:
	set(value):
		health = clampi(value, 0, max_health)
		#print_debug("health: ", health)
		health_changed.emit(health)
		if health <= 0:
			died.emit()
			queue_free()


## Raw attack power.
@export var attack_damage: int = 1:
	set(value):
		attack_damage = value
		stats_changed.emit(self)

## Defence power. WARNING: not used.
@export var defence: int = 1:
	set(value):
		defence = value
		stats_changed.emit(self)

## Movement speed in pixels per second.
@export var speed: float = 64:
	set(value):
		speed = value
		stats_changed.emit(self)

@export_category("Leveling")
## [Player] level.
@export var level: int = 1:
	set(value):
		level = value
		stats_changed.emit(self)

## [Player] experience points.
@export var experience_points = 0:
	set(value):
		experience_points = value
		while experience_points >= experience_to_next_level:
			experience_points -= experience_to_next_level
			level_up()
		gain_experience.emit(experience_points, experience_to_next_level)

## [member max_health] gained on a level up.
@export var level_up_max_health: int = 10
## [member health] restored on a level up.
@export var level_up_healing: int = 20
## [member attack_damage] stat increase on level up.
@export var level_up_attack: int = 1

## Experience points needed to level up.
var experience_to_next_level: int


@export_category("Movement")
## Velocity the [Player] gets knocked back in pixels/second.
@export var knockback_speed: float = 256

## Drop off rate for the knockback using [method Vector2.lerp].
@export_range(0, 1) var knockback_dropoff = 0.1
## Current veloctiy of the knockback effect.
var knockback_velocity: Vector2 = Vector2.ZERO
## Duration of the knockback gamepad vibration in seconds.
@export var knockback_vibration_duration: float = 0.2
## Knockback low motor gamepad vibration.
@export_range(0, 1) var knockback_low_vibration: float = 0.2
## Knockback high motor gamepad vibration.
@export_range(0, 1) var knockback_high_vibration: float = 0.4

@export_category("Haptic")
## Duration of the weapon strike gamepad vibration in seconds.
@export var strike_enemy_low_vibration: float = 0.1
## Weapon strike low motor gamepad vibration.
@export_range(0, 1) var strike_enemy_strong_vibration: float = 0.1
## Weapon strike high motor gamepad vibration.
@export_range(0, 1) var strike_enemy_vibration_duration: float = 0.1


@export_category("Lantern")
## Lantern brightness.
@export var lantern_luminosity: float
## Lantern range in pixels.
@export var lantern_range: float


@export_category("Animation")
## [AnimationTree] reference.
@onready var animation_tree: AnimationTree = $AnimationTree
## [$AnimationPlayer] reference.
@onready var animation_player: AnimationPlayer = $AnimationPlayer
## Cached reference to [AnimationTree][code][&"parameters/playback"][/code].
@onready var playback_state: AnimationNodeStateMachinePlayback = animation_tree[&"parameters/playback"]
## Cached refrence to the duck sprite.
@onready var duck_sprite: Sprite2D = $DuckSprite

## Direction the player is moving in.
var direction: Vector2 = Vector2.ZERO
## Direction the player last moved in.
var last_direction: Vector2 = Vector2.DOWN

## Flag to determing if the attack animation is playing.
@export var is_attacking: bool = false

## Flag to determing if the cast animation is playing. WARNING: not used.
@export var is_casting: bool = false

## Flag to determing if the carry item animation is playing. WARNING: not used.
var is_using_item: bool = false

## Flag used by damage animation.
@export var is_damaged: bool = false

## Duration of the attack cycle in seconds.
var attack_duration: float = 0.3
## Span of time since the last player attack in seconds.
var time_since_attack: float = 0
## [Tween] used for damage animation.
var damage_tween: Tween = null
## Duration of the blink animation in seconds.
@export var blink_duration: float = 0.2

var floating_text_scene: PackedScene = preload("res://scenes/user interface/floating_text.tscn")

## Called when all children are ready. Makes sure the [AnimationTree] is active and starts [member playback_state].
func _ready() -> void:
	# Start animations if turned off in editor
	animation_tree.active = true
	
	# Start animation state machine.
	playback_state.start(&"Start")
	
	# Initialize level.
	experience_to_next_level = get_exp_to_next_level(level)

	# Initialize UI.
	health_changed.emit(health)
	max_health_changed.emit(max_health)
	stats_changed.emit(self)
	
	#Quack
	var floating_text: FloatingText = floating_text_scene.instantiate()
	floating_text.text = "[rainbow]QUACK![/rainbow]"
	floating_text.tween_duration = 2.0
	floating_text.rise_height = -40
	add_child(floating_text)




## Handles movement and manages the animation state machine.
func _physics_process(delta: float) -> void:
	direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	
	velocity = (direction * speed) + knockback_velocity
	#print_debug("knockback velocity: ", knockback_velocity)
	
	# Skip actions if player is attacking
	if is_attacking:
		time_since_attack += delta
		if time_since_attack < attack_duration:
			return
		is_attacking = false
		time_since_attack = 0
	
	# Attack when standing still.
	elif Input.is_action_just_pressed(&"attack") and direction.is_zero_approx():
		playback_state.travel(&"Attack")
		animation_tree["parameters/Attack/BlendSpace2D/blend_position"] = last_direction
	
	# Attack when moving.
	elif Input.is_action_just_pressed(&"attack") and not direction.is_zero_approx():
		playback_state.travel(&"Attack")
		animation_tree["parameters/Attack/BlendSpace2D/blend_position"] = direction
	
	# Do idle animation if player is not moving.
	elif direction.is_zero_approx():
		playback_state.travel(&"Idle")
		animation_tree["parameters/Idle/BlendSpace2D/blend_position"] = last_direction
		
	# Move player and use moving animation.
	elif not direction.is_zero_approx():
		last_direction = direction
		playback_state.travel(&"Walk")
		animation_tree["parameters/Walk/BlendSpace2D/blend_position"] = direction

	move_and_slide()
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_dropoff)


## Called when an [Enemy] body hits the [Player]. Calls [member hit_by_enemy].
## WARNING: Only enemy collisons are handled, enemy projectiles/attacks are not.
func _on_hurt_box_area_entered(area: Area2D) -> void:
	#print_debug("area: ", area, ", area name: ", area.name)
	#print_debug("area parent: ", area.get_parent())
	#print_debug("is area parent enemy? ", area.get_parent() is Enemy)
	if area.get_parent() is Enemy:
		hit_by_enemy(area.get_parent() as Enemy)


## Handles hitting an [Enemy] with the sword.
func _on_sword_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		#var enemy: Enemy = body as Enemy
		# TODO: play sword hit sound here.
		Input.start_joy_vibration(0, strike_enemy_low_vibration, strike_enemy_strong_vibration, strike_enemy_vibration_duration)


## Sets the [member knockback_velocity] to the opposite vector of the [Enemy]'s [member CharacterBody2D.velocity]. STarts vibration. Plays hurt animation.
func hit_by_enemy(enemy: Enemy) -> void:
	var old_health: int = health
	knockback_velocity = (enemy.velocity - velocity).normalized() * knockback_speed
	#print("dam ",health)
	health -= maxi(enemy.attack - defence, 1) #does minimum 1 damage - no armor can prevent this.
	#print(health)
	#playback_state.travel(&"Hurt")
	# Using tween instead of AnimationTree state.
	damage_tween = get_tree().create_tween()
	damage_tween.tween_method(set_blink_shader, 1.0, 0, blink_duration)
	
	Input.start_joy_vibration(0, knockback_low_vibration, knockback_high_vibration, knockback_vibration_duration)
	
	var damage_message: FloatingText = floating_text_scene.instantiate()
	damage_message.push_color(Color.RED)
	damage_message.append_text(str("-", old_health - health))
	damage_message.pop()
	add_child(damage_message)
	

## Simple function to get the EXP needed for the next level
func get_exp_to_next_level(current_level: int) -> int:
	return current_level * 10
	

## Levels up the player.
func level_up() -> void:
	level += 1
	max_health += level_up_max_health
	health += level_up_healing
	attack_damage += level_up_attack
	experience_to_next_level = get_exp_to_next_level(level)
	leveled_up.emit(level)
	
	var level_up_label: FloatingText = floating_text_scene.instantiate()
	level_up_label.text = str("[rainbow][wave]Level ", level, "![/wave][/rainbow]")
	
	level_up_label.tween_duration = 3.0
	add_child(level_up_label)



## Sets the blink intensity for the blink shader when the player is hit.
func set_blink_shader(intensity: float) -> void:
	duck_sprite.material["shader_parameter/blink_intensity"] = intensity


## Catches slain enemies and applies the EXP.
func _on_slain_enemy(_slain_enemy_name: StringName, points: int) -> void:
	experience_points += points
	#print_debug(points, " EXP gained from slaying ", _slain_enemy_name)
	
