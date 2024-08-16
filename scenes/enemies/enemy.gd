## Base class for the enemy. Handles navigation, health, death.
class_name Enemy
extends CharacterBody2D

## Emitted when enemy slain, gives name and points.
signal slain(enemy_name: StringName, points: int)

## [Enemy] maximum health.
@export var max_health: int

## Current [Enemy] health. Clamped to [member max_health].
@export var health: int:
	set(value):
		health = clampi(value, 0, max_health)

## Attack damage.
@export var attack: int

## Movement speed in pixel/second.
@export var speed: float

## [Node] the [Enemy] is targeting.
@export var target: Node2D = null

## Cached [NavigationAgent2D] reference. Initialized in [method _ready].
@onready var navigator: NavigationAgent2D = %Navigator


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred(&"_setup_navigation_seeker")




## Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Update to the target current position.
	if target:
		navigator.target_position = target.global_position
	# Currently do nothing if destination is reached.
	if navigator.is_navigation_finished():
		return
	
	# Get vector to next path point and set to character velocity * speed.
	var next_path_position: Vector2 = navigator.get_next_path_position()
	velocity = global_position.direction_to(next_path_position) * speed

	move_and_slide()


## Waits one physics frame, then updates the [NavigationAgent2D.target_position] to [member target]'s [Node2D.global_position].
func _setup_navigation_seeker() -> void:
	# Wait 1 frame
	await get_tree().physics_frame
	if target:
		navigator.target_position = target.global_position
