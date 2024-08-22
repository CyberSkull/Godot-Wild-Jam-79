@icon("res://graphics/Dakota Duck/Dakota Duck icon.png")
## Class for the [Player] character.
class_name Player
extends CharacterBody2D

## Emitted when the [Player] gains or looses [member health] or [member max_health].
signal health_changed(health: int)
## Emitted when the [Player] gains or looses [member health] or [member max_health].
signal max_health_changed(max_health: int)
## Emitted when a buff changes. WARNING: Not currently used.
signal buff_changed(player: Player)
## Emitted when the [Player] dies. Triggers game over.
signal died()

## Gold carried by player.
var gold: int = 0:
	set(value):
		gold = value
		buff_changed.emit(self)

## Maximum [Player] health. Emits [signal health_changed] when changed.
@export var max_health: int = 100:
	set(value):
		max_health = value
		max_health_changed.emit(health)


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
		buff_changed.emit(self)

## Defence power. WARNING: not used.
@export var defence: int = 1:
	set(value):
		defence = value
		buff_changed.emit(self)

## Movement speed in pixels per second.
@export var speed: float = 64:
	set(value):
		speed = value
		buff_changed.emit(self)

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

## Duration of the weapon strike gamepad vibration in seconds.
@export var strike_enemy_low_vibration: float = 0.1
## Weapon strike low motor gamepad vibration.
@export_range(0, 1) var strike_enemy_strong_vibration: float = 0.1
## Weapon strike high motor gamepad vibration.
@export_range(0, 1) var strike_enemy_vibration_duration: float = 0.1


## Lantern brightness.
@export var lantern_luminosity: float
## Lantern range in pixels.
@export var lantern_range: float


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



## Called when all children are ready. Makes sure the [AnimationTree] is active and starts [member playback_state].
func _ready() -> void:
	# Start animations if turned off in editor
	animation_tree.active = true
	
	# Start animation state machine.
	playback_state.start(&"Start")
	
	# Initialize UI.
	health_changed.emit(health)
	max_health_changed.emit(max_health)
	buff_changed.emit(self)




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
		var enemy: Enemy = body as Enemy
		# TODO: play sword hit sound here.
		Input.start_joy_vibration(0, strike_enemy_low_vibration, strike_enemy_strong_vibration, strike_enemy_vibration_duration)


## Sets the [member knockback_velocity] to the opposite vector of the [Enemy]'s [member CharacterBody2D.velocity]. STarts vibration. Plays hurt animation.
func hit_by_enemy(enemy: Enemy) -> void:
	knockback_velocity = (enemy.velocity - velocity).normalized() * knockback_speed
	#print("dam ",health)
	health -= maxi(enemy.attack - defence, 1) #does minimum 1 damage - no armor can prevent this.
	#print(health)
	#playback_state.travel(&"Hurt")
	# Using tween instead of AnimationTree state.
	damage_tween = get_tree().create_tween()
	damage_tween.tween_method(set_blink_shader, 1.0, 0, blink_duration)
	
	Input.start_joy_vibration(0, knockback_low_vibration, knockback_high_vibration, knockback_vibration_duration)
	

func set_blink_shader(intensity: float) -> void:
	duck_sprite.material["shader_parameter/blink_intensity"] = intensity
