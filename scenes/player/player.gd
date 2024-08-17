@icon("res://graphics/Dakota Duck/Dakota Duck icon.png")
## Class for the [Player] character.
class_name Player
extends CharacterBody2D

## Emitted when the [Player] gains or looses [member health] or [member max_health].
signal health_changed(health: int)
## Emitted when the [Player] gains or looses [member health] or [member max_health].
signal max_health_changed(max_health: int)
## Emitted when a buff changes. WARNING: Not currently used.
signal buff_changed()
## Emitted when the [Player] dies. Triggers game over.
signal died()


## Maximum [Player] health. Emits [signal health_changed] when changed.
@export var max_health: int = 100:
	set(value):
		max_health = value
		max_health_changed.emit(health)


## Current [Player] health. Clamped to [member max_health]. Emits [signal health_changed] when changed. Emits [signal died] when <= 0.
@export var health: int = 100:
	set(value):
		health = clampi(value, 0, max_health)
		print_debug("health: ", health)
		health_changed.emit(health)
		if health <= 0:
			died.emit()


## Raw attack power.
@export var attack_damage: int
## Defence power. WARNING: not used.
@export var defence: int

## Movement speed in pixels per second.
@export var speed: float = 64
## Velocity the [Player] gets knocked back in pixels/second.
@export var knockback_speed: float = 256

## Drop off rate for the knockback using [method Vector2.lerp].
@export_range(0, 1) var knockback_dropoff = 0.1
## Current veloctiy of the knockback effect.
var knockback_velocity: Vector2 = Vector2.ZERO
## Duration of the knockback gamepad vibration in seconds.
@export var knockback_vibration_duration: float = 0.2
## Knockback low motor gamepad vibration.
@export_range(0, 1) var knockback_low_vibration: float = 0.1
## Knockback low motor gamepad vibration.
@export_range(0, 1) var knockback_high_vibration: float = 0.2

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



## Called when all children are ready. Makes sure the [AnimationTree] is active and starts [member playback_state].
func _ready() -> void:
	# Start animations if turned off in editor
	animation_tree.active = true
	
	# Start animation state machine.
	playback_state.start(&"Start")




## Handles movement and manages the animation state machine.
func _physics_process(delta: float) -> void:
	direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_dropoff)
	velocity = (direction * speed) + knockback_velocity
	#print_debug("knockback velocity: ", knockback_velocity)
	
	# Skip actions if player is attacking
	if is_attacking:
		return
	
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
	
	
	# if animation, then don't check this
	#is_attacking = Input.is_action_just_pressed(&"attack")
	#is_casting = Input.is_action_just_pressed(&"cast")
	#is_using_item = Input.is_action_just_pressed(&"item")

	#print_debug("velocity: ", velocity)
	move_and_slide()
	#move_and_collide(velocity)
	#print_debug("velocity: ", velocity)


## Called when an [Enemy] body hits the [Player]. Sets the [member knockback_velocity] to the opposite vector of the [Enemy]'s [member CharacterBody2D.velocity].
## WARNING: Only enemy collisons are handled, enemy projectiles/attacks are not.
func _on_hurt_box_area_entered(area: Area2D) -> void:
	print_debug("area: ", area, ", area name: ", area.name)
	print_debug("area parent: ", area.get_parent())
	print_debug("is area parent enemy? ", area.get_parent() is Enemy)
	if area.get_parent() is Enemy:
		var enemy: Enemy = area.get_parent()
		knockback_velocity = (enemy.velocity - velocity).normalized() * knockback_speed
		health -= enemy.attack
		Input.start_joy_vibration(0, knockback_low_vibration, knockback_high_vibration, knockback_vibration_duration)


func _on_sword_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
