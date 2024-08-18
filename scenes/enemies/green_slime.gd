@icon("res://graphics/slime/Green Slime icon.png")
class_name green_slime
extends Enemy

## Cached [AnimationPlayer] reference.
@onready var animation_player: AnimationPlayer = $AnimationPlayer
## Cached [AnimationTree] reference.
@onready var animation_tree: AnimationTree = $AnimationTree
## Playback state of the [AnimationTree].
@onready var playback_state: AnimationNodeStateMachinePlayback = animation_tree[&"parameters/playback"]

var last_direction = Vector2.LEFT

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	# Start animations if turned off in editor
	animation_tree.active = true
	
	# Start animation state machine.
	playback_state.start(&"Start")
	



## Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super(delta)
	if health <= 0:
		print_debug("Setting travel to Death.")
		playback_state.travel(&"Death")
		animation_tree["parameters/Death/BlendSpace1D/blend_position"] = velocity.x
	elif not knockback_velocity.is_zero_approx():
		print_debug("Traveling to HURT")
		playback_state.travel(&"Hurt")
		animation_tree["parameters/Hurt/BlendSpace1D/blend_position"] = knockback_velocity.x
	elif velocity.is_zero_approx():
		playback_state.travel(&"Idle")
		animation_tree["parameters/Idle/BlendSpace1D/blend_position"] = velocity.x
	else:
		# Moving animation and pass horizontal movement to blend.
		playback_state.travel(&"Moving")
		animation_tree["parameters/Moving/BlendSpace1D/blend_position"] = velocity.x
	
