class_name Enemy
extends CharacterBody2D


## [Enemy] maximum health.
@export var max_health: int

## Current [Enemy] health. Clamped to [member max_health].
@export var health: int:
	set(value):
		health = clampi(value, 0, max_health)

## Movement speed in pixel/second.
@export var speed: float

## [Node] the [Enemy] is targeting.
@export var target: Node



## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	pass
