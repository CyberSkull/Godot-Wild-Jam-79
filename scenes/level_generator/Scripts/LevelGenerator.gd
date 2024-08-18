@icon("res://graphics/dungeon/Dungeon icon.png")
extends Node2D
class_name LevelGenerator

@export var generator_resource : LevelGenerationSettings

# replaced in code with vector2i.UP, etc.
#helper values
#add these to your node location to "move" your value in that direction.
#const move_north:=Vector2i(0,-1) #UP
#const move_east:=Vector2i(1,0) #LEFT
#const move_south:=Vector2i(0,1) #DOWN
#const move_west:=Vector2i(-1,0) #RIGHT



const LAYER_IDX: int = 0
const SRC_IDX: int = 0 #sometimes this changes for like no reason.

const direction_iter: Array=[Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]

var room_spacing: Vector2i
var room_list: RoomList
var random: RandomNumberGenerator

var world_extent : Vector2i
var real_world_extent_top_left: Vector2i
var real_world_extent_bot_right: Vector2i

var current_level: int = 0

var total_enemy_spawn_chance: int
var enemy_spawn_chances_for_current_level: Dictionary

var enemy_spawn_list: Dictionary

var debug_mode: bool = 0
var debug_bricks
var debug_lines
var debug_loc

var player_instance: Player

var tilemap_helper: Dictionary
var tilemap_helper_sz: int = 8

@export var logical_wall := Vector2i.ZERO
@export var logical_floor := Vector2i.LEFT

class RoomStruct:
	#roomspace
	var node_loc: Vector2i
	
	var direction_arr:Array[RoomStruct]
	
	func north() -> RoomStruct: return direction_arr[0]
	func east() -> RoomStruct:  return direction_arr[1]
	func south() -> RoomStruct: return direction_arr[2]
	func west() -> RoomStruct:  return direction_arr[3]
	
	func north_loc() -> Vector2i: return node_loc + Vector2i.UP
	func east_loc() -> Vector2i:  return node_loc + Vector2i.RIGHT
	func south_loc() -> Vector2i: return node_loc + Vector2i.DOWN
	func west_loc() -> Vector2i:  return node_loc + Vector2i.LEFT
	
	#tilespace
	var area: Vector2i
	#position offset from top left of room base tilespace cell
	var wiggled: Vector2i
	#tilespace top left, for reuse
	var cell_top_left: Vector2i
	#tilespace bot right, for reuse
	var cell_bot_right: Vector2i
	
	var is_enterance: bool
	var is_exit: bool
	
	var room_list: RoomList
	
	var generator_resource: LevelGenerationSettings
	var random: RandomNumberGenerator
	
	func recurse_make_new_room()->RoomStruct:
		var idx: int= random.randi_range(0, 3)
		var selected_room: RoomStruct= direction_arr[idx];
		var new_node_loc: Vector2i = node_loc + direction_iter[idx]
		var possibly_existing_room = room_list.all[new_node_loc.x][new_node_loc.y]
		#if we find a room there already... JUST MAKE THAT ONE RESPONSIBLE NOW! HAHA.
		if possibly_existing_room != null:
			return possibly_existing_room.recurse_make_new_room()
		if (selected_room == null):
			selected_room = room_list.add_node(new_node_loc)
			selected_room.direction_arr[(idx + 2) % 4] = self
			direction_arr[idx] = selected_room
			return selected_room;
		return selected_room.recurse_make_new_room()


	func get_random_filled_node()->RoomStruct:
		var rand_arr:Array = Array()
		if north() != null: rand_arr.push_back(north()) 
		if east() != null: rand_arr.push_back(east()) 
		if south() != null: rand_arr.push_back(south()) 
		if west() != null: rand_arr.push_back(west()) 
		if rand_arr.size() == 0: return null;
		return rand_arr[random.randi_range(0, rand_arr.size() - 1)]


	func is_full()->bool:
		return north() != null and east() != null and south() != null and west() != null;


	func get_wall_start_position(facing_index: int) -> Vector2i:
		var edgepoints: Array=[
				Vector2i(cell_top_left),
				Vector2i(cell_bot_right.x, cell_top_left.y),
				Vector2i(cell_bot_right),
				Vector2i(cell_top_left.x, cell_bot_right.y)
			]
		return edgepoints[facing_index];
	
	func get_wall_end_position(facing_index: int) -> Vector2i:
		var edgepoints: Array = [
				Vector2i(cell_bot_right.x, cell_top_left.y),
				Vector2i(cell_bot_right),
				Vector2i(cell_top_left.x, cell_bot_right.y),
				Vector2i(cell_top_left)
			]
		return edgepoints[facing_index];


class RoomList:
	var all: Array[Array]
	var root_node_loc: Vector2
	var random: RandomNumberGenerator
	var completed_passages: Array[Vector4i]#could turn this into a dictionary for faster look up time. don't care enough to figure out the gdscript impl rn
	
	
	func has_completed_passage(loc_a: Vector2i, loc_b: Vector2i) -> bool:
		var search_a:Vector4i = Vector4i(loc_a.x, loc_a.y, loc_b.x, loc_b.y)
		var search_b:Vector4i = Vector4i(loc_b.x, loc_b.y, loc_a.x, loc_a.y)
		
		if completed_passages.find(search_a) != -1:
			return true
		if completed_passages.find(search_b) != -1:
			return true
		return false;


	func add_completed_passage(loc_a: Vector2i, loc_b: Vector2i) -> void:
		var search_a:Vector4i= Vector4i(loc_a.x, loc_a.y, loc_b.x, loc_b.y)
		var search_b:Vector4i= Vector4i(loc_b.x, loc_b.y, loc_a.x, loc_a.y)
		
		completed_passages.push_back(search_a)
		completed_passages.push_back(search_b)


	func add_node(loc : Vector2i)->RoomStruct:
		if all[loc.x][loc.y] != null:
			print("what the fuck")
			return;
		var new_room = RoomStruct.new();
		for v in range(4):
			new_room.direction_arr.push_back(null)
		new_room.room_list = self
		new_room.random = random
		new_room.node_loc = loc
		print("made room: ", loc)
		all[loc.x][loc.y] = new_room
		return all[loc.x][loc.y];


	func make_root_node(base_loc : Vector2i):
		for x_idx in range(0, base_loc.x*2+1):
			all.push_back(Array())
			for y_idx in range(0, base_loc.y*2+1):
				all[x_idx].push_back(null)
		root_node_loc = base_loc
		add_node(root_node_loc).is_enterance = true


	## Adds additional node links between neighbour rooms.
	func fixup_node_links():
		# TODO: make this work, and have it be optional.
		pass
	
	func get_root() -> RoomStruct:
		return all[root_node_loc.x][root_node_loc.y]
	
	#does not replace existing links, which is why it is a "maybe"
	func maybe_add_link_between(room_a:RoomStruct, a_to_b_dir:int, room_b:RoomStruct, b_to_a_dir:int)->bool:
		if room_a.direction_arr[a_to_b_dir] == null || room_b.direction_arr[b_to_a_dir] == null:
			room_a.direction_arr[a_to_b_dir] = room_b
			room_b.direction_arr[b_to_a_dir] = room_a
			return true;
		return false;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func gen_room_box(minimum: int, mamimum: int) -> Rect2i:
	return Rect2i(Vector2i(0,0), Vector2i(random.randi_range(minimum, mamimum), random.randi_range(minimum, mamimum)));

func room_space_to_tile_map_space(loc: Vector2i) -> Vector2i:
	return (loc * room_spacing) + Vector2i(generator_resource.base_room_margin, generator_resource.base_room_margin)

#random item from array, deterministic.
func rand_arr_itm_det(val: Array):
	return val[random.randi_range(0,val.size()-1)];

#silly helper that doesn't REALLY need to exist, but it can help make logic clearer.
func is_horizontal_dir(direction: int) -> int:
	return direction % 2

func logical_world_fill(start:Vector2i, end:Vector2i):
	var tm: TileMap = $LogicalTiles
	for pos_x in range(start.x, end.x):
		for pos_y in range(start.y, end.y):
			tm.set_cell(LAYER_IDX, Vector2i(pos_x, pos_y), SRC_IDX, logical_wall);

#creates a room from top left to bottom right in size.
#walls optional.
#corner walls will be created only when adjacent walls are true.
func room_cutter(
		logical_tile: Vector2i,
		room_top_left: Vector2i,
		room_bot_right: Vector2i
	) -> void:
	var tm: TileMap = $LogicalTiles
	
	#print("making room: ",room_top_left, room_bot_right)
	
	for pos_x: int in range(room_top_left.x, room_bot_right.x + 1):
		for pos_y: int in range(room_top_left.y, room_bot_right.y + 1):
			tm.set_cell(LAYER_IDX, Vector2i(pos_x, pos_y), SRC_IDX, logical_tile);
			#3x3 grid to ensure everything all around is valid.
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz) - 1, (pos_y / tilemap_helper_sz) - 1)] = true
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz) - 1, (pos_y / tilemap_helper_sz))] = true
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz) - 1, (pos_y / tilemap_helper_sz) + 1)] = true
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz), (pos_y / tilemap_helper_sz) - 1)] = true
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz), (pos_y / tilemap_helper_sz))] = true
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz), (pos_y / tilemap_helper_sz) + 1)] = true
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz) + 1, (pos_y / tilemap_helper_sz) - 1)] = true
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz) + 1, (pos_y / tilemap_helper_sz))  ] = true
			tilemap_helper[Vector2i((pos_x / tilemap_helper_sz) + 1, (pos_y / tilemap_helper_sz) + 1)] = true
			

func loop_make_room_walls(room: RoomStruct) -> void:
	
	if room == null:
		return
	
	# WARNING!
	# Obviously there is something wrong here!
	# The room sizes should be correct, and there should be a margin allowed for walls to be created.
	# The math isn't working out properly, so this probably should be rewritten.
	# Thank you Future Cole. I am sure this will look really dope when it's done!
	
	print_debug("sized room: ", room.node_loc)
	
	var margin = Vector2i(generator_resource.base_room_margin, generator_resource.base_room_margin)
	
	room.area = Vector2i(random.randi_range(generator_resource.base_room_size_min, generator_resource.base_room_size_max) - 1, random.randi_range(generator_resource.base_room_size_min, generator_resource.base_room_size_max) - 1)
	#make wiggle room area, then move it randomly within that.
	room.wiggled = room_spacing - room.area - margin - Vector2i(1, 1)
	room.wiggled = Vector2i(random.randi_range(0, room.wiggled.x), random.randi_range(0, room.wiggled.y))
	
	room.cell_top_left = room_space_to_tile_map_space(room.node_loc);
	room.cell_bot_right = room.cell_top_left + room.area
	
	
	
	
	var tm :TileMap = $LogicalTiles
	#add wiggle
	room.cell_top_left += room.wiggled
	room.cell_bot_right += room.wiggled
	
	var debugsz = Vector2(tm.tile_set.tile_size.x * 0.5, tm.tile_set.tile_size.y * 0.5)
	if debug_mode:
		debug_bricks.push_back(Vector2(tile_space_to_pixel_space(room.cell_top_left)) + debugsz)
		debug_bricks.push_back(Vector2(tile_space_to_pixel_space(room.cell_bot_right)) + debugsz)
	
	var found = -1
	#obviously if I were programming this for a not-game-jam,
	#I would make this code be more generic and use virtual functions to make room "types"
	if room.is_enterance:#entrance cannot be weird room
		found = 0
	else:
		var dict = Dictionary()
		var tchance = generator_resource.chance_of_normal_room 
		dict[tchance] = 0
		tchance += generator_resource.chance_of_weird_room_no1 
		dict[tchance] = 1
		tchance += generator_resource.chance_of_weird_room_no2
		dict[tchance] = 2
		tchance += generator_resource.chance_of_weird_room_no3
		dict[tchance] = 3
		tchance += generator_resource.chance_of_weird_room_no4
		dict[tchance] = 4
		tchance += generator_resource.chance_of_weird_room_no5
		dict[tchance] = 5
		tchance += generator_resource.chance_of_weird_room_no6
		dict[tchance] = 6
		#yuck
		var value = random.randi_range(0, tchance-1)
		var sorted_keys = dict.keys()
		sorted_keys.sort()#just in case the keys are unordered as they often will be in maps/dictionaries.
		
		for chance in sorted_keys:
			if (value < chance):
				found = dict[chance]
				break
		
		if found == -1:
			print("FAIL BAD ROOM INDEX")
	match found:
		0:
			#normal room
			room_cutter(logical_floor, room.cell_top_left, room.cell_bot_right)
			return
		1:
			#circle room with 1 width halls
			room_cutter(logical_floor, room.cell_top_left, room.cell_bot_right)
			room_cutter(logical_wall, room.cell_top_left+Vector2i(1,1), room.cell_bot_right-Vector2i(1,1))
			return
		2:
			#circle room with 1 width halls and 2 width halls (dependant on orientation)
			room_cutter(logical_floor, room.cell_top_left, room.cell_bot_right)
			room_cutter(logical_wall, room.cell_top_left+Vector2i(1,2), room.cell_bot_right-Vector2i(1,2))
			return
		3:
			#circle room with 1 width halls and 2 width halls (dependant on orientation)
			room_cutter(logical_floor, room.cell_top_left, room.cell_bot_right)
			room_cutter(logical_wall, room.cell_top_left+Vector2i(2,1), room.cell_bot_right-Vector2i(2,1))
			return
		4:
			#circle room with a center cross hallway in the middle
			room_cutter(logical_floor, room.cell_top_left, room.cell_bot_right)
			room_cutter(logical_wall, room.cell_top_left+Vector2i(1,1), room.cell_bot_right-Vector2i(1,1))
			room_cutter(logical_floor, room.cell_top_left+Vector2i(room.area.x/2, 0), room.cell_bot_right+Vector2i(-room.area.x/2, 0))
			room_cutter(logical_floor, room.cell_top_left+Vector2i(0, room.area.y/2), room.cell_bot_right+Vector2i(0, -room.area.y/2))
			return
		5:
			#cross wall in center of room, dividing the room into 4 rooms usually (on smaller rooms it looks similar to earlier room types)
			room_cutter(logical_floor, room.cell_top_left, room.cell_bot_right)
			room_cutter(logical_wall, room.cell_top_left+Vector2i(room.area.x/2, 1), room.cell_bot_right+Vector2i(-room.area.x/2, -1))
			room_cutter(logical_wall, room.cell_top_left+Vector2i(1, room.area.y/2), room.cell_bot_right+Vector2i(-1, -room.area.y/2))
			return
		6:
			#room with grid pillars
			room_cutter(logical_floor, room.cell_top_left, room.cell_bot_right)
			var odd_x:bool= !bool(room.area.x%2)
			var odd_y:bool= !bool(room.area.y%2)
			if odd_x && odd_y:
				for x in range(room.cell_top_left.x+1, room.cell_bot_right.x, 2):
					for y in range(room.cell_top_left.y+1, room.cell_bot_right.y, 2):
						room_cutter(logical_wall, Vector2i(x,y), Vector2i(x,y))
				return
			if odd_x:
				for x in range(room.cell_top_left.x+1, room.cell_bot_right.x, 2):
					room_cutter(logical_wall, Vector2i(x,room.cell_top_left.y+1), Vector2i(x,room.cell_bot_right.y-1))
				return
			if odd_y:
				for y in range(room.cell_top_left.y+1, room.cell_bot_right.y, 2):
					room_cutter(logical_wall, Vector2i(room.cell_top_left.x+1, y), Vector2i(room.cell_bot_right.x-1, y))
				return
			room_cutter(logical_wall, Vector2i(room.cell_top_left.x+room.area.x/2, room.cell_top_left.y+room.area.y/2), 
			Vector2i(room.cell_bot_right.x-room.area.x/2, room.cell_bot_right.y-room.area.y/2))
			return
	return


func _draw():
	if debug_mode:
		for idx in range(0, debug_lines.size(), 2):
			draw_line(debug_lines[idx], debug_lines[idx+1], Color(1,1,1), 5)
			
		for idx in range(debug_bricks.size()):
			draw_circle(debug_bricks[idx],12.0, Color(0.8,0.2,0.8))
			var vreal = debug_bricks[idx]/32
			draw_string(ThemeDB.fallback_font, debug_bricks[idx], str(vreal))

#generic passage cutter function, allows cutting passages between two points 
func passage_cutter(start:Vector2i, finish:Vector2i, passage_width:int, is_start_direction_horizontal:bool, is_end_direction_horizontal:bool):
	var tm :TileMap = $LogicalTiles
	#var distance:Vector2i=start-finish 
	
	var points : Array = Array()
	points.push_back(start)
	
	#print("try make passage ", start, " to ", finish)
	
	var debugsz = Vector2(tm.tile_set.tile_size.x*0.5,tm.tile_set.tile_size.y*0.5)
	if debug_mode:
		debug_bricks.push_back(Vector2(tile_space_to_pixel_space(start))+debugsz)
		debug_bricks.push_back(Vector2(tile_space_to_pixel_space(finish))+debugsz)
	
	#if start and and are not the same orientation, that means we can create an L shaped passage
	if is_start_direction_horizontal != is_end_direction_horizontal:
		if !is_start_direction_horizontal:#up/down, across
			points.push_back(Vector2i(start.x, finish.y))
			points.push_back(finish)
		else:#across, up/down
			points.push_back(Vector2i(finish.x, start.y))
			points.push_back(finish)
	else:#if start and end are both in the same orientation, we can make a Z-(ish) shaped passage.
		if !is_start_direction_horizontal:#up/down halfway, across, up/down halfway
			var halfpoint_y :int= (start.y + finish.y)/2 #integer/integer division. could result in weird values, beware.
			points.push_back(Vector2i(start.x, halfpoint_y))
			points.push_back(Vector2i(finish.x, halfpoint_y))
			points.push_back(finish)
		else:#across halfway, up/down, across halfway
			var halfpoint_x :int= (start.x + finish.x)/2 #integer/integer division. could result in weird values, beware.
			points.push_back(Vector2i(halfpoint_x, start.y))
			points.push_back(Vector2i(halfpoint_x, finish.y))
			points.push_back(finish)
	

	#index from and to, making a single passage between the two
	for point_idx in range(0, points.size()-1):
		var from : Vector2i = points[point_idx]
		var to : Vector2i = points[point_idx+1]
		var from2 = Vector2i(min(to.x,from.x),min(to.y,from.y))
		var to2 = Vector2i(max(to.x,from.x),max(to.y,from.y))
		if debug_mode:
			debug_lines.push_back(Vector2(tile_space_to_pixel_space(from2))+debugsz)
			debug_lines.push_back(Vector2(tile_space_to_pixel_space(to2))+debugsz)
		
		room_cutter(logical_floor, from2, to2)
	

func _gen_room_passage_sort_helper(room : RoomStruct, direction:int)->Vector2i:
	var vec_a:Vector2i= room.get_wall_start_position(direction)
	var vec_b:Vector2i= room.get_wall_end_position(direction)
	
	var int_a:int
	var int_b:int
	var vert:bool
	
	if !is_horizontal_dir(direction):
		vert = true
		int_a = vec_a.x
		int_b = vec_b.x
	else:
		vert = false
		int_a = vec_a.y
		int_b = vec_b.y
	
	var start_idx = random.randi_range(min(int_a, int_b),max(int_a, int_b))
	var output:Vector2i
	
	if vert:
		output = Vector2i(start_idx, vec_a.y)
	else:
		output = Vector2i(vec_a.x, start_idx)
	return output

func generate_room_passge(room_a : RoomStruct, room_b : RoomStruct)->bool:
	#no entry if already made a passage between these two rooms.. 
	if room_list.has_completed_passage(room_a.node_loc, room_b.node_loc):
		return false;
	room_list.add_completed_passage(room_a.node_loc, room_b.node_loc)
	
	#print("passage:", room_a.node_loc, " to ", room_b.node_loc)
	
	#find closest wall between rooms, then delete walls and add passageway walls
	var a_to_b_direction:int=-1
	var b_to_a_direction:int=-1
	
	for dir_idx in range(0, room_a.direction_arr.size()):
		if room_a.direction_arr[dir_idx] == room_b:
			a_to_b_direction = dir_idx
			break
	
	for dir_idx in range(0, room_b.direction_arr.size()):
		if room_b.direction_arr[dir_idx] == room_a:
			b_to_a_direction = dir_idx
			break
	
	
	var start:Vector2i=_gen_room_passage_sort_helper(room_a, a_to_b_direction)
	var finish:Vector2i=_gen_room_passage_sort_helper(room_b, b_to_a_direction)
	#todo: make passage width a different value. this is prob gonna cause issues rn
	passage_cutter(start, finish, 3, is_horizontal_dir(a_to_b_direction), is_horizontal_dir(b_to_a_direction))
	return true;


#if from vector is the same as the room loc, that signifies that it is allowed to make a passage in all directions.
func recurse_make_room_passages(room : RoomStruct, from : Vector2i):
	if (room.north() != null && room.north_loc() != from):
		if generate_room_passge(room, room.north()):
			recurse_make_room_passages(room.north(), room.node_loc)
	if (room.east() != null && room.east_loc() != from):
		if generate_room_passge(room, room.east()):
			recurse_make_room_passages(room.east(), room.node_loc)
	if (room.south() != null && room.south_loc() != from):
		if generate_room_passge(room, room.south()):
			recurse_make_room_passages(room.south(), room.node_loc)
	if (room.west() != null && room.west_loc() != from):
		if generate_room_passge(room, room.west()):
			recurse_make_room_passages(room.west(), room.node_loc)

#returns the two nearest facing directions to a given node location.
#If it is directly in a single direction, the second value in the return will be -1 (none)
#this is a gross func. dislike it, but idc to make it cleaner yet.
func get_two_nearest_directions(from:Vector2i, to:Vector2i)->Vector2i:
	if (from == to):
		return Vector2i(-1,-1)
	
	var diff:Vector2i= from - to
	var diff_abs:Vector2i= diff.abs()
	
	if diff_abs.x == 0:#both are inline on x
		var sng = signi(diff.x)
		if sng == 1:
			return Vector2i(1,-1) 
		if sng == -1:
			return Vector2i(3,-1) 
	elif diff_abs.y == 0:#both are inline on y
		var sng = signi(diff.y)
		if sng == 1:
			return Vector2i(0,-1)
		if sng == -1:
			return Vector2i(2,-1)
	else:#different size xy, return two directions.
		var out:Vector2i
		var sngx = signi(diff.x)
		if sngx == 1:
			out.x = 1 
		if sngx == -1:
			out.x = 3
		var sngy = signi(diff.y)
		if sngy == 1:
			out.y = 0
		if sngy == -1:
			out.y = 2
		return out
	return Vector2i()#???? why? what a silly lang

func swizzle(to_swizzle:Vector2i)->Vector2i:
	return Vector2i(to_swizzle.y, to_swizzle.x)

func tile_space_to_pixel_space(loc:Vector2i)->Vector2i:
	var tm :TileMap = $LogicalTiles
	return tm.tile_set.tile_size * loc

func handle_room_additional_connection(room:RoomStruct):
	for idx in range(room.direction_arr.size()):
		if generator_resource.chance_add_passageway_between_neighbour_rooms_per_room > random.randf_range(0,1):
			var other_room :RoomStruct= room.direction_arr[idx]
			if (other_room != null):
				continue
			var to_check :Vector2i= room.node_loc + direction_iter[idx]
			var unconnected_room :RoomStruct= room_list.all[to_check.x][to_check.y]
			if  unconnected_room == null:
				continue
			unconnected_room.direction_arr[(idx+2)%4] = room
			room.direction_arr[idx] = unconnected_room

#takes in the room and the list of already used tiles in the room, and outputs a new tile for the enemy to be spawned in.
func find_floor_spaces(room:RoomStruct, ignore_list:Array[Vector2i])->Array:
	var tm :TileMap = $LogicalTiles
	var locations:Array[Vector2i] = []
	#cannot remember if should be +1 or not.
	for x in range(room.cell_top_left.x, room.cell_bot_right.x+1):
		for y in range(room.cell_top_left.y, room.cell_bot_right.y+1):
			var test_loc = Vector2i(x,y)
			if ignore_list.find(test_loc) != -1:
				continue
			
			if (tm.get_cell_atlas_coords(0, test_loc)==logical_floor):
				locations.push_back(test_loc)
	
	if locations.size() > 0:
		return [true, rand_arr_itm_det(locations)]
	return [false]

func handle_room_enemy_spawns(room:RoomStruct):
	var tm :TileMap = $LogicalTiles
	if room.is_enterance:
		return
	if generator_resource.chance_empty_room > random.randf_range(0,1):
		return
	var num_enemies = random.randi_range(generator_resource.number_enemies_min, generator_resource.number_enemies_max)
	print("num enemies: ",num_enemies)
	var ignore_list :Array[Vector2i]= []
	
	for i in range(num_enemies):
		var enemy_type :EnemySetting= get_random_enemy_type()
		var space = find_floor_spaces(room, ignore_list)
		if space[0]:
			var new_enemy:Enemy= enemy_type.enemy_type.instantiate()
			new_enemy.target = player_instance
			print("made enemy: ",enemy_type.enemy_name)
			add_child(new_enemy)
			var location :Vector2i = tile_space_to_pixel_space(space[1])
			#enemy_spawn_list[location] = enemy_type.enemy_type
			new_enemy.position = Vector2(location) + Vector2(tm.tile_set.tile_size.x/2,tm.tile_set.tile_size.y/2)#not sure why we need this offset?
	
	pass

func get_random_enemy_type()->EnemySetting:
	var value = random.randi_range(0, total_enemy_spawn_chance-1)
	var sorted_keys = enemy_spawn_chances_for_current_level.keys()
	sorted_keys.sort()#just in case the keys are unordered as they often will be in maps/dictionaries.
	for chance in sorted_keys:
		if (value < chance):
			return enemy_spawn_chances_for_current_level[chance]
	
	print("error, random enemy type was bad!")
	return null;

func compute_spawn_chances():
	enemy_spawn_chances_for_current_level = Dictionary()
	total_enemy_spawn_chance = 0;
	for enemy_setting in generator_resource.enemy_types:
		var enemy_chance = enemy_setting.spawn_chance_base + (enemy_setting.spawn_chance_per_level*current_level)
		#ensure non-negative chance
		if enemy_chance > 0:
			total_enemy_spawn_chance+=enemy_chance
			enemy_spawn_chances_for_current_level[total_enemy_spawn_chance] = enemy_setting

func handle_spawn_room_items(room:RoomStruct):
	var tm :TileMap = $LogicalTiles
	
	var ignore_list:Array[Vector2i]=[];
	for idx in range(0, mini(generator_resource.objects.size(), generator_resource.objects_per_room.size())):
		var spawn_range:Vector2i = generator_resource.objects_per_room[idx]
		var num_to_spawn = maxi(random.randi_range(spawn_range.x, spawn_range.y),0)
		for to_spawn_idx in range(0, num_to_spawn):
			var loc = find_floor_spaces(room, ignore_list)
			if (loc[0] == false):
				#no more locations in room!
				return;
			ignore_list.push_back(loc[1])
			
			var new_object = generator_resource.objects[idx].instantiate()
			new_object.position = Vector2(tile_space_to_pixel_space(loc[1])) + Vector2(tm.tile_set.tile_size.x/2,tm.tile_set.tile_size.y/2)
			add_child(new_object)
		

func end_level():
	var level = get_parent() as Level
	level.create_level(current_level+1)


#bind the function for exiting 
func generate(in_random: RandomNumberGenerator, level : int):
	if (generator_resource == null):
		return;
	
	var tm :TileMap = $LogicalTiles
	var vm :TileMap = $VisibleTiles
	var fm :TileMap = $FeatureTiles
	#tm.tile_set = generator_resource.tile_set
	
	random = in_random
	
	#debug crap
	if debug_mode:
		debug_lines = Array()
		debug_bricks = Array()
	
	room_spacing = Vector2i(generator_resource.base_room_size_max, generator_resource.base_room_size_max) + Vector2i(generator_resource.base_room_margin, generator_resource.base_room_margin)

	
	#set level difficulty.
	current_level = level;
	
	var numRooms :int= random.randi_range(generator_resource.base_number_of_rooms_min, generator_resource.base_number_of_rooms_max)
	
	room_list = RoomList.new()
	room_list.random = random;
	
	# root node will always be at max number of rooms * max number of rooms in order to ensure all rooms can fit in any linear direction.
	var root_node_loc := Vector2i(generator_resource.base_number_of_rooms_max, generator_resource.base_number_of_rooms_max);
	
	#+1 just in case.
	world_extent = room_space_to_tile_map_space((root_node_loc*2)+Vector2i(1,1))
	
	real_world_extent_bot_right = world_extent
	real_world_extent_top_left = world_extent
	#fill world with wall
	logical_world_fill(Vector2i(0,0),  world_extent)
	
	room_list.make_root_node(root_node_loc)
	var cur_num_rooms = 1
	var all_rooms = Array()
	
	#todo: add exit room (can just use last room generated as exit.
	#It has the potential to be right beside the enterance, but whatever.
	all_rooms.push_back(room_list.get_root())
	while cur_num_rooms < numRooms:
		all_rooms.push_back(room_list.get_root().recurse_make_new_room())
		cur_num_rooms += 1;
	
	#todo: make exit and enterance nodes a certain dist from each other.
	
	#make basic room layouts/positions, set up walls and floors
	for room:RoomStruct in all_rooms:
		loop_make_room_walls(room)
	
	#add additional passages between rooms
	for room:RoomStruct in all_rooms:
		handle_room_additional_connection(room)
	
	for room:RoomStruct in all_rooms:
		handle_spawn_room_items(room)
	
	#precompute enemy spawn chances
	compute_spawn_chances()
	#spawn enemies
	for room:RoomStruct in all_rooms:
		handle_room_enemy_spawns(room)
	print("finished spawning enemies")
	
	var root_room:RoomStruct = room_list.get_root()
	recurse_make_room_passages(root_room, root_room.node_loc)
	
	player_instance.position = tile_space_to_pixel_space((root_room.cell_top_left + root_room.cell_bot_right)/2)
	var exit_room :RoomStruct = all_rooms[all_rooms.size()-1]
	
	exit_room.is_exit = true

	var exit_loc = find_floor_spaces(exit_room, [])
	if exit_loc[0] == false:
		print("CRITICAL ERROR: NO EXIT!")
		return
	
	var exit_obj = generator_resource.exit_object.instantiate()
	exit_obj.random = random
	$VisibleTiles.add_child(exit_obj)
	exit_obj.position = Vector2(tile_space_to_pixel_space(exit_loc[1]))# + Vector2(tm.tile_set.tile_size.x/2,tm.tile_set.tile_size.y/2)
	
	#gather real world limits to only use create_visible within that range.
	#doesn't work right now, idk why, don't really care.
	for room:RoomStruct in all_rooms:
		real_world_extent_top_left = Vector2i(mini(room.cell_top_left.x, real_world_extent_top_left.x), mini(room.cell_top_left.y, real_world_extent_top_left.x))
		real_world_extent_bot_right = Vector2i(maxi(room.cell_bot_right.x, real_world_extent_bot_right.x), maxi(room.cell_bot_right.y, real_world_extent_bot_right.x))
	print("creating visible level...")
	#print(real_world_extent_top_left, real_world_extent_bot_right)
	create_visible(Vector2i(0,0), world_extent)
	print("done!")

func setup_cell_visual(logical_cell:Vector2i):
	var tm :TileMap = $LogicalTiles
	var vm :TileMap = $VisibleTiles
	
	var compare = logical_wall
	
	var av = Vector2i(logical_cell.x  ,logical_cell.y  )
	var bv = Vector2i(logical_cell.x+1,logical_cell.y  )
	var cv = Vector2i(logical_cell.x  ,logical_cell.y+1)
	var dv = Vector2i(logical_cell.x+1,logical_cell.y+1)
	
	#attempted optimization for level gen, doesn't work very much faster though ngl. Only like 1 second faster on a normally 5 second generation..
	if tilemap_helper.has(av/tilemap_helper_sz) || tilemap_helper.has(bv/tilemap_helper_sz) || tilemap_helper.has(cv/tilemap_helper_sz) || tilemap_helper.has(dv/tilemap_helper_sz):
		var a:bool=tm.get_cell_atlas_coords(0, av)==compare #top left
		var b:bool=tm.get_cell_atlas_coords(0, bv)==compare #top right
		var c:bool=tm.get_cell_atlas_coords(0, cv)==compare #bot left
		var d:bool=tm.get_cell_atlas_coords(0, dv)==compare #bot right
		
		var combine=Vector2i(int(a) | int(b)<<1, int(c) | int(d)<<1)
		
		vm.set_cell(LAYER_IDX, logical_cell, 0, combine);
	

func create_visible(real_extent_top_left:Vector2i, real_extent_bot_right:Vector2i):
	#todo: loop all grid cells and then
	for x in range(real_extent_top_left.x, real_extent_bot_right.x):
		for y in range(real_extent_top_left.y, real_extent_bot_right.y):
			setup_cell_visual(Vector2i(x,y))

func spawn_waiting_enemies()->void:
	var tm :TileMap = $LogicalTiles
	var enemyloc = enemy_spawn_list.keys()[0]
	
	var new_enemy:Enemy= enemy_spawn_list[enemyloc].instantiate()
	new_enemy.target = player_instance
	var location :Vector2i = tile_space_to_pixel_space(enemyloc)
	add_child(new_enemy)
	new_enemy.position = Vector2(location) + Vector2(tm.tile_set.tile_size.x/2,tm.tile_set.tile_size.y/2)#not sure why we need this offset?
	print("added enemy")
	enemy_spawn_list.erase(enemyloc)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#REALLY BAD DOES NOT WORK WELL.
	while enemy_spawn_list.size() > 0:
		spawn_waiting_enemies()
