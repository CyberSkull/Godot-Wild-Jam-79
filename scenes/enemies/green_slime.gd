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
	
	print_debug("navigator: ", navigator)
	pass


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super(delta)
	pass
