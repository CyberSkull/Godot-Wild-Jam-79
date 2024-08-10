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
@export var attack: int

## Defence power.
@export var defence: int

## Movement speed in pixels per second.
@export var speed: float = 500

## Lantern brightness.
@export var lantern_luminosity: float

## Lantern range in pixels.
@export var lantern_range: float



func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector( &"move_left", &"move_right", &"move_up", &"move_down")
	
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta
	
	move_and_slide()
