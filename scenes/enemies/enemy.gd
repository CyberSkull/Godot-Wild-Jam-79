## Base class for the enemy. Handles navigation, health, death.
class_name Enemy
extends CharacterBody2D

## Emitted when enemy slain, gives name and points.
signal slain(slain_enemy_name: StringName, points: int)

## [Enemy] name.
@export var enemy_name: StringName = "Enemy"

## [Enemy] maximum health.
@export var max_health: int = 1

## Current [Enemy] health. Clamped to [member max_health].
@export var health: int = 1:
	set(value):
		health = clampi(value, 0, max_health)
		if health <= 0:
			slain.emit(enemy_name, experience_points)
		#print_debug(name, " health: ", health, "/", max_health)

## Attack damage.
@export var attack: int = 1

## Movement speed in pixel/second.
@export var speed: float = 20

## Knockback velocity in pixels per second.
@export var knockback_speed: float = 128

## Experience points when given to player when defeating the enemy.
@export var experience_points: int = 1

var knockback_velocity: Vector2 = Vector2.ZERO

# Attenuation rate of the [member knockback_velocty].
@export_range(0, 1) var knockback_attenuation: float = 0.1

## [Node] the [Enemy] is targeting.
@export var target: Node2D = null
var target_last_known_pos: Vector2

@export var aggro_dist: float = 100
@export var lose_aggro_dist: float = 500
@export var lose_aggro_dist_but_still_visible_debuff: float = 0.4
@export var lose_agro_time: float = 2.5
var lose_agro_time_current: float = lose_agro_time + 1


#standard search stuff
@export var search_distance_min: float = 15
@export var search_distance_max: float = 40
@export var time_between_searches_min: float = 7.5
@export var time_between_searches_max: float = 20
var time_to_next_search: float = 0

## The amount of time to do an "intensive search" after seeing an enemy
@export var search_acceleration_after_seen_time: float = 30
## Multiplier to the duration between searches during the "intensive search"
@export var search_acceleration_after_seen_multiplier: float = 0.20
## Multiplier to the search distance during the "intensive search"
@export var search_area_after_seen_multiplier: float = 2.5
## Time since we were aggroed on an enemy.
## If this falls within the search_acceleration_after_seen_time, it will be an intensive search.
var time_since_last_target: float = 0

## The target to be searched for, ususally the [Player].
var search_target: Vector2

## Cached [NavigationAgent2D] reference. Initialized in [method _ready].
@onready var navigator: NavigationAgent2D = %Navigator

## First physics frame check.
var first_physic: bool = true
## Controls if the enemy is navigating. WARNING: unused.
var is_navigating: bool = false

## [PackedScene] containing the floating text for [Enemy] damage.
var floating_text_scene: PackedScene = preload("res://scenes/user interface/floating_text.tscn")


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect velocity computed signal.
	#navigator.velocity_computed.connect(Callable(_on_navigator_velocity_computed))
	pass


func set_no_aggro() -> void:
	lose_agro_time_current = lose_agro_time + 1

	
func is_aggroed() -> bool:
	return lose_agro_time_current < lose_agro_time;
	

func determine_aggro_state(delta :float):
	if target == null:
		set_no_aggro()
		return
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, target.position)
	
	#need to get RID for these. whatever for now.
	#query.exclude.push_back(target)
	#query.exclude.push_back(self)
	var result = space_state.intersect_ray(query)
	#if the target is seen…
	if result.size() && result["collider"] == target || result.size() == 0:
		#target is within aggro range! Get him!
		if target.position.distance_to(self.position) < aggro_dist:
			lose_agro_time_current = 0
			target_last_known_pos = target.global_position
		#target is a bit far away, but we still have a line of sight…
		#tick down lose aggro time, but penalize the time a bit… Better to break line of sight!
		elif is_aggroed() && target_last_known_pos.distance_to(self.position) > lose_aggro_dist:
			lose_agro_time_current += delta * lose_aggro_dist_but_still_visible_debuff
			target_last_known_pos = target.global_position
	#okay, the target is not seen, but I can guess where he's going!
	elif is_aggroed():
		target_last_known_pos = target.global_position
		lose_agro_time_current += delta;


func increment_time_since_seen(delta: float) -> void:
	if time_since_last_target < search_acceleration_after_seen_time:#don't do it if we're over anyway
		time_since_last_target += delta


func reset_search_time() -> void:
	time_to_next_search = -1
	time_since_last_target = 0


func search_logic(delta: float) -> Vector2:
	if time_to_next_search < 0:
		var random_dir: float = randf_range(0, TAU)
		
		var search_distance = randf_range(search_distance_min, search_distance_max)
		#if seen enemy recently, search more often!
		if time_since_last_target > 0 && time_since_last_target < search_acceleration_after_seen_time:
			#extend the search distance too!
			search_distance *= search_area_after_seen_multiplier
			time_to_next_search = randf_range(time_between_searches_min, time_between_searches_max)*search_acceleration_after_seen_multiplier
		else:#normal search time.
			time_to_next_search = randf_range(time_between_searches_min, time_between_searches_max)
		
		var search_range:Vector2 = Vector2(search_distance, 0)
		#no update last known position. Just anchor around it.
		search_target = target_last_known_pos + search_range.rotated(random_dir)
		
	time_to_next_search -= delta
	return search_target


## Handles taking damage from a [Player] hit.
func hit_by_player(player: Player) -> void:
	#knockback_velocity = (player.velocity - velocity).normalized() * knockback_speed
		knockback_velocity = -global_position.direction_to(player.global_position) * knockback_speed
		if health > 0:
			health -= player.attack_damage
			var damage_text: FloatingText= floating_text_scene.instantiate()
			damage_text.push_color(Color.WHITE)
			damage_text.append_text(str("-", player.attack_damage))
			damage_text.pop()
			add_child(damage_text)
		elif health <= 0:
			experience_points = 0 # prevents double exp
			target = self # mostly stops momentum towards player on death.


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Return if map is not ready.
	if NavigationServer2D.map_get_iteration_id(navigator.get_navigation_map()) == 0:
		return
	
	# Annoyingly, ready is called IMMEDIATELY upon instantiation, which leaves no time to set stuff up before moving the enemy to position due to this, I have this silly functionality here, which is definitely not the best way to do it.
	# Just is a hack for now (obvi would rather have a timer set for next tick to do this functionality..)
	if first_physic == true:
		#pre zero the velocity to ensure no weirdness happens.
		velocity = Vector2.ZERO
		target_last_known_pos = self.position
		#artificially low amount of time before searching here, just to get the enemies into different positions
		time_to_next_search = randf_range(1, time_between_searches_min)
		search_target = self.position
		first_physic = false
		time_since_last_target = search_acceleration_after_seen_time+1
	
	# Update to the target current position.
	if target:
		determine_aggro_state(delta)
		if is_aggroed():
			reset_search_time()
			navigator.target_position = target_last_known_pos
		else:
			increment_time_since_seen(delta)
			navigator.target_position = search_logic(delta)
	# Currently do nothing if destination is reached.
	if navigator.is_navigation_finished():
		#must be set to stop movement, and to allow the idle anim to play
		velocity = Vector2.ZERO
		return
	# Get vector to next path point and set to character velocity * speed.
	var next_path_position: Vector2
	next_path_position = navigator.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * speed + knockback_velocity
	if navigator.avoidance_enabled:
		navigator.set_velocity(new_velocity)
	else:
		_on_navigator_velocity_computed(new_velocity)
	
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_attenuation)


## Provides a small delay to alow the navigation server to sync.
func _on_navigator_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()


## Handles collision with [Player]'s weapons.
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.get_parent().get_parent() is Player:
		hit_by_player(area.get_parent().get_parent() as Player)
