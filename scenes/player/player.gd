@icon("res://graphics/Dakota Duck/Dakota Duck icon.png")
class_name Player
extends CharacterBody2D

## Emitted when the [Player] gains or looses [member health] or [member max_health].
signal health_changed(current: int, max: int)
## Emitted when a buff changes.
signal buff_changed()
## Emitted when the [Player] dies. Triggers game over.
signal died()


## Maximum [Player] health.
@export var max_health: int = 100

## Current [Player] health.
@export var health: int = 100:
	set(value):
		health = clampi(value, 0, max_health)

## Raw attack power.
@export var attack_damage: int

## Defence power.
@export var defence: int

## Movement speed in pixels per second.
@export var speed: float = 64

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


## Called when all children are ready.
func _ready() -> void:
	# start animations if turned off in editor
	animation_tree.active = true
	
	# Start animation state machine.
	playback_state.start(&"Start")




## Handles the animation cycle.
func _physics_process(delta: float) -> void:
	direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	
	# Handle the attack.
	if Input.is_action_just_pressed(&"attack"):
		playback_state.travel(&"Attack")
		animation_tree["parameters/Attack/BlendSpace2D/blend_position"] = direction
	# Skip actions if player is attacking.
	elif is_attacking:
		return
	# Do idle animation if player is not moving.
	elif direction.is_zero_approx():
		playback_state.travel(&"Idle")
		animation_tree["parameters/Idle/BlendSpace2D/blend_position"] = last_direction
		
	# Move player and use moving animation.
	elif not direction.is_zero_approx():
		global_position += direction * speed * delta
		last_direction = direction
		playback_state.travel(&"Walk")
		animation_tree["parameters/Walk/BlendSpace2D/blend_position"] = direction
	
	
	# if animation, then don't check this
	#is_attacking = Input.is_action_just_pressed(&"attack")
	#is_casting = Input.is_action_just_pressed(&"cast")
	#is_using_item = Input.is_action_just_pressed(&"item")
	
	move_and_slide()
