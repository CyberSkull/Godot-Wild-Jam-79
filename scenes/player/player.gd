@icon("res://graphics/Dakota Duck/Dakota Duck icon.png")
class_name Player
extends CharacterBody2D

signal health_changed(current: int, max: int)
signal buff_changed()
signal died()


## Maximum player health.
@export var max_health: int = 100

## Current player health.
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

var state: AnimationNodeStateMachinePlayback

## [class AnimationTree] reference.
@onready var animation_tree: AnimationTree = $AnimationTree


## Direction the player is moving in.
var direction: Vector2 = Vector2.ZERO
## Direction the player last moved in.
var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var is_casting: bool = false
var is_using_item: bool = false


## Called when all children are ready
func _ready() -> void:
	state = animation_tree[&"parameters/playback"]
	state.start(&"Start")
	print_debug("animation state machine: ", state)
	state.travel(&"Idle")
	


## Handles the animation cycle.
func _physics_process(delta: float) -> void:	
	direction = Input.get_vector( &"move_left", &"move_right", &"move_up", &"move_down")
	
	if direction.is_zero_approx():
		state.travel(&"Idle")
		animation_tree["parameters/Idle/BlendSpace2D/blend_position"] = last_direction
	else:
		global_position += direction * speed * delta
		last_direction = direction
		state.travel(&"Walk")
		animation_tree["parameters/Walk/BlendSpace2D/blend_position"] = direction
	
	
	# if animation, then don't check this
	#is_attacking = Input.is_action_just_pressed(&"attack")
	#is_casting = Input.is_action_just_pressed(&"cast")
	#is_using_item = Input.is_action_just_pressed(&"item")
	
	move_and_slide()
	

## Handles attacking animaton and damage
func attack(delta: float) -> void:
	pass

