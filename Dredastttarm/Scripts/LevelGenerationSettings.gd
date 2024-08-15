extends Resource
class_name LevelGenerationSettings

@export_group("Map Overall")
@export var branch_pass_on_chance: float = 0.5
@export var passageway_width: int = 3
@export var chance_add_passageway_between_neighbour_rooms_per_room:float=0.25

@export_group("Room")
@export var base_room_size_min:int = 25
@export var base_room_size_max:int= 50
@export var base_room_margin:int= 1#minimum distance between rooms
@export var chance_of_weird_room_no1:float=0.1
@export var chance_of_weird_room_no2:float=0.05
@export var chance_of_weird_room_no3:float=0.05

@export_group("Items per room")
@export var base_number_of_rooms_min:int= 2
@export var base_number_of_rooms_max:int= 5
@export var number_items_per_room_min:int= 2
@export var number_items_per_room_max:int= 5

@export_group("Tile Set")
@export var tile_set : TileSet;

