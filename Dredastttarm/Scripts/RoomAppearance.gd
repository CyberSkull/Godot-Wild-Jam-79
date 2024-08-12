extends Resource
class_name RoomAppearance

@export_group("Room appearance tiles")
@export var floor_basic:Array[Vector2i]

@export var wall_facing_north:Array[Vector2i]
@export var wall_facing_east:Array[Vector2i]
@export var wall_facing_south:Array[Vector2i]
@export var wall_facing_west:Array[Vector2i]

@export var wall_inner_corner_facing_north_east:Array[Vector2i]
@export var wall_inner_corner_facing_south_east:Array[Vector2i]
@export var wall_inner_corner_facing_south_west:Array[Vector2i]
@export var wall_inner_corner_facing_north_west:Array[Vector2i]

@export var wall_outer_corner_facing_north_east:Array[Vector2i]
@export var wall_outer_corner_facing_south_east:Array[Vector2i]
@export var wall_outer_corner_facing_south_west:Array[Vector2i]
@export var wall_outer_corner_facing_north_west:Array[Vector2i]

