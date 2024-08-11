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
@export var speed: float = 500

## Lantern brightness.
@export var lantern_luminosity: float

## Lantern range in pixels.
@export var lantern_range: float



func _physics_process(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO
	var is_attacking: bool = false
	var is_casting: bool = false
	var is_using_item: bool = false
	
	direction = Input.get_vector( &"move_left", &"move_right", &"move_up", &"move_down")
	
	# if animation, then don't check this
	is_attacking = Input.is_action_just_pressed(&"attack")
	is_casting = Input.is_action_just_pressed(&"cast")
	is_using_item = Input.is_action_just_pressed(&"item")
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta
	
	move_and_slide()
	

## Handles attacking animaton and damage
func attack(delta: float) -> void:
	pass

