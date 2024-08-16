@icon("res://graphics/slime/Green Slime icon.png")
class_name green_slime
extends Enemy

## Cached [AnimationPlayer] reference.
@onready var animation_player: AnimationPlayer = $AnimationPlayer
## Cached [AnimationTree] reference.
@onready var animation_tree: AnimationTree = $AnimationTree
## Playback state of the [AnimationTree].
@onready var playback_state: AnimationNodeStateMachinePlayback = animation_tree[&"parameters/playback"]

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	# start animations if turned off in editor
	animation_tree.active = true
	
	# Start animation state machine.
	playback_state.start(&"Start")
	



## Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super(delta)
	if velocity.is_equal_approx(Vector2.ZERO):
		playback_state.travel(&"Idle")
	else:
		# Moving animation and pass horizontal movement to blend.
		playback_state.travel(&"Moving")
		animation_tree["parameters/Moving/BlendSpace1D/blend_position"] = velocity.x
	
