extends Node

@export var generator_resource : LevelGenerationSettings

#helper values
#add these to your node location to "move" your value in that direction.
const move_north:=Vector2i(0,-1)
const move_east:=Vector2i(1,0)
const move_south:=Vector2i(0,1)
const move_west:=Vector2i(-1,0)

const layer_idx:int=0
const src_idx:int=1

const direction_iter:Array=[Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]

var room_spacing:Vector2i
var room_list:RoomList
var random:RandomNumberGenerator
class RoomStruct:
	#roomspace
	var node_loc: Vector2i
	
	var direction_arr:Array[RoomStruct]
	
	func north()->RoomStruct: return direction_arr[0]
	func east()->RoomStruct: return direction_arr[1]
	func south()->RoomStruct: return direction_arr[2]
	func west()->RoomStruct: return direction_arr[3]
	
	func north_loc()->Vector2i: return node_loc + move_north
	func east_loc()->Vector2i: return node_loc + move_east
	func south_loc()->Vector2i: return node_loc + move_south
	func west_loc()->Vector2i: return node_loc + move_west
	
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
	
	var room_list:RoomList
	
	#the set of tiles that should be used for this room
	var room_appearance : RoomAppearance
	
	var generator_resource : LevelGenerationSettings
	var random : RandomNumberGenerator
	
	func add_to_random_unfilled():
		var nempty :int = -1
		if north() == null: nempty += 1
		if east() == null: nempty += 1
		if south() == null: nempty += 1
		if west() == null: nempty += 1
		
		var rand = random.randi_range(0, nempty)
		
		#get to our random node and make a new node
		#terrible copy paste because afaik there is no passing references to class variables
		if north() == null:
			if rand == 0:
				room_list.add_node(north_loc()).direction_arr[2] = self
				return;
			else:
				rand -= 1
		if east() == null:
			if rand == 0:
				room_list.add_node(east_loc()).direction_arr[3] = self
				return;
			else:
				rand -= 1
		if south() == null:
			if rand == 0:
				room_list.add_node(south_loc()).direction_arr[0] = self
				return;
		#west does not need to do any of the decrementation, since by elimination it is the correct one.
		room_list.add_node(west_loc()).direction_arr[1] = self
		return;
	
	func get_random_filled_node()->RoomStruct:
		var rand_arr : Array
		if north() != null: rand_arr.push_back(north()) 
		if east() != null: rand_arr.push_back(east()) 
		if south() != null: rand_arr.push_back(south()) 
		if west() != null: rand_arr.push_back(west()) 
		if rand_arr.size() == 0: return null;
		return rand_arr[random.randi_range(0, rand_arr.size())]
	
	func is_full()->bool:
		return north() != null && east() != null && south() != null && west() != null;
	
	#outputs new number of rooms
	func expand_maybe():
		var random_node : RoomStruct = get_random_filled_node();
		if (random_node != null):
			if (is_full() || random.randf_range(0,1) < generator_resource.branch_pass_on_chance):
				random_node.expand_maybe();
				return;
		add_to_random_unfilled()
	
	func get_wall_start_position(facing_index:int)->Vector2i:
		var edgepoints : Array=[Vector2i(cell_top_left), Vector2i(cell_bot_right.x, cell_top_left.y), Vector2i(cell_bot_right), Vector2i(cell_top_left.x, cell_bot_right.y)]
		return edgepoints[facing_index];
	
	func get_wall_end_position(facing_index:int)->Vector2i:
		var edgepoints : Array=[Vector2i(cell_bot_right.x, cell_top_left.y), Vector2i(cell_bot_right), Vector2i(cell_top_left.x, cell_bot_right.y), Vector2i(cell_top_left)]
		return edgepoints[facing_index];

class RoomList:
	var all: Array[Array]
	var root_node_loc : Vector2
	var random : RandomNumberGenerator
	var completed_passages:Array[Vector4i]#could turn this into a dictionary for faster look up time. don't care enough to figure out the gdscript impl rn
	
	func has_completed_passage(loc_a : Vector2i, loc_b : Vector2i)->bool:
		var search_a:Vector4i= Vector4i(loc_a.x,loc_a.y, loc_b.x,loc_b.y)
		var search_b:Vector4i= Vector4i(loc_b.x,loc_b.y, loc_a.x,loc_a.y)
		
		if completed_passages.find(search_a) != -1:
			return true
		if completed_passages.find(search_b) != -1:
			return true
		return false;
	
	func add_completed_passage(loc_a : Vector2i, loc_b : Vector2i):
		var search_a:Vector4i= Vector4i(loc_a.x,loc_a.y, loc_b.x,loc_b.y)
		var search_b:Vector4i= Vector4i(loc_b.x,loc_b.y, loc_a.x,loc_a.y)
		
		completed_passages.push_back(search_a)
		completed_passages.push_back(search_b)
	
	func add_node(loc : Vector2i)->RoomStruct:
		var new_room = RoomStruct.new();
		for v in range(4):
			new_room.direction_arr.push_back(null)
		new_room.room_list = self
		new_room.random = random
		new_room.node_loc = loc
		all[loc.x][loc.y] = new_room
		return all[loc.x][loc.y];
	
	func make_root_node(base_loc : Vector2i):
		for x_idx in range(0, base_loc.x*2-1):
			all.push_back(Array())
			for y_idx in range(0, base_loc.y*2-1):
				all[x_idx].push_back(null)
		root_node_loc = base_loc
		add_node(root_node_loc)
	
	#adds additional node links between neighbour rooms
	func fixup_node_links():
		#todo: make this work, and have it be optional.
		pass
	
	func get_root()->RoomStruct:
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
	generate(randi())
	pass # Replace with function body.

func gen_room_box(random : RandomNumberGenerator, min : int, max : int)->Rect2i:
	return Rect2i(Vector2i(0,0), Vector2i(random.randi_range(min, max), random.randi_range(min, max)));

func room_space_to_tile_map_space(loc : Vector2i)->Vector2i:
	return loc * room_spacing

#random item from array, deterministic.
func rand_arr_itm_det(val : Array):
	return val[random.randi_range(0,val.size()-1)];

#silly helper that doesn't REALLY need to exist, but it can help make logic clearer.
func is_horizontal_dir(direction:int)->int:
	return direction % 2

#creates a room from top left to bottom right in size.
#walls optional.
#corner walls will be created only when adjacent walls are true.
func room_cutter(room_appearance:RoomAppearance,
	room_top_left:Vector2i,
	room_bot_right:Vector2i,
	wall_north:bool=true,
	wall_east:bool=true,
	wall_south:bool=true,
	wall_west:bool=true):
	var tm : TileMap = $WorldMap
	
	#var layer_idx:int = tm.
	#var src_idx:int = 
	
	#set floor tiles
	for pos_x in range(room_top_left.x+1, room_bot_right.x-1):
		for pos_y in range(room_top_left.y+1, room_bot_right.y-1):
			tm.set_cell(layer_idx, Vector2i(pos_x, pos_y), src_idx, rand_arr_itm_det(room_appearance.floor_basic));
	
	#north wall
	if wall_north:
		for pos_y in range(room_top_left.y+1, room_bot_right.y-1):
			var pos_x = room_top_left.x#dumb gd script doesn't let me make arbitrary scopes with no preceeding statement, so I have to put this variable here. It's just an alias anyway
			tm.set_cell(layer_idx, Vector2i(pos_x, pos_y), src_idx, rand_arr_itm_det(room_appearance.wall_facing_south));
	#south wall
	if wall_south:
		for pos_y in range(room_top_left.y+1, room_bot_right.y-1):
			var pos_x = room_bot_right.x#dumb gd script doesn't let me make arbitrary scopes with no preceeding statement, so I have to put this variable here. It's just an alias anyway
			tm.set_cell(layer_idx, Vector2i(pos_x, pos_y), src_idx, rand_arr_itm_det(room_appearance.wall_facing_north));
	#east wall
	if wall_east:
		for pos_x in range(room_top_left.x+1, room_bot_right.x-1):
			var pos_y = room_top_left.y#dumb gd script doesn't let me make arbitrary scopes with no preceeding statement, so I have to put this variable here. It's just an alias anyway
			tm.set_cell(layer_idx, Vector2i(pos_x, pos_y), src_idx, rand_arr_itm_det(room_appearance.wall_facing_west));
	#west wall
	if wall_west:
		for pos_x in range(room_top_left.x+1, room_bot_right.x-1):
			var pos_y = room_top_left.y#dumb gd script doesn't let me make arbitrary scopes with no preceeding statement, so I have to put this variable here. It's just an alias anyway
			tm.set_cell(layer_idx, Vector2i(pos_x, pos_y), src_idx, rand_arr_itm_det(room_appearance.wall_facing_east));
	
	#corners
	#not sure if the coords are right for these, need to test!
	if wall_north && wall_east:
		tm.set_cell(layer_idx, Vector2i(room_top_left.x, room_bot_right.y), src_idx, rand_arr_itm_det(room_appearance.wall_inner_corner_facing_south_west));
	if wall_north && wall_west:
		tm.set_cell(layer_idx, Vector2i(room_top_left.x, room_top_left.y), src_idx, rand_arr_itm_det(room_appearance.wall_inner_corner_facing_south_east));
	if wall_south && wall_east:
		tm.set_cell(layer_idx, Vector2i(room_bot_right.x, room_bot_right.y), src_idx, rand_arr_itm_det(room_appearance.wall_inner_corner_facing_north_west));
	if wall_south && wall_west:
		tm.set_cell(layer_idx, Vector2i(room_bot_right.x, room_top_left.y), src_idx, rand_arr_itm_det(room_appearance.wall_inner_corner_facing_north_east));

func loop_make_room_walls(room : RoomStruct):
	room.cell_top_left = room_space_to_tile_map_space(room.node_loc);
	room.cell_bot_right = room.cell_top_left + room.area
	
	room.room_appearance = rand_arr_itm_det(generator_resource.room_appearances)
	
	var tm :TileMap = $WorldMap
	#add wiggle
	room.cell_top_left += room.wiggled
	room.cell_bot_right += room.wiggled
	
	
	room_cutter(room.room_appearance, room.cell_top_left, room.cell_bot_right)
	print("made walls at ", room.cell_top_left, " and ", room.cell_bot_right)

#generic passage cutter function, allows cutting passages between two points 
func passage_cutter(appearance:RoomAppearance, start:Vector2i, finish:Vector2i, passage_width:int, is_start_direction_horizontal:bool, is_end_direction_horizontal:bool):
	var tm :TileMap = $WorldMap
	#var distance:Vector2i=start-finish 
	
	var points : Array[Vector2i]
	points.push_back(start)
	
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
	for point_idx in range(0, points.size()-2):
		var from : Vector2i = points[point_idx]
		var to : Vector2i = points[point_idx+1]
		#get direction to determine cut side.
		var distance:Vector2i=to-from
		
		#if last point, we also need to clear the ending wall to cut into the end point room
		var make_end_wall = point_idx+1 == points.size()-1
		
		var wall_north : bool = distance.y < 0 || (make_end_wall && distance.y != 0)
		var wall_east : bool = distance.x < 0 || (make_end_wall && distance.x != 0)
		var wall_south : bool = distance.y > 0 || (make_end_wall && distance.y != 0)
		var wall_west : bool = distance.x > 0 || (make_end_wall && distance.x != 0)
		
		room_cutter(appearance, from, to, wall_north, wall_east, wall_south, wall_west)
	

func _gen_room_passage_sort_helper(room : RoomStruct, direction:int)->Vector2i:
	var vec_a:Vector2i= room.get_wall_start_position(direction)
	var vec_b:Vector2i= room.get_wall_end_position(direction)
	
	var int_a:int
	var int_b:int
	var vert:bool
	
	if !is_horizontal_dir(direction):
		vert = true
		int_a = vec_a.y
		int_b = vec_b.y
	else:
		vert = false
		int_a = vec_a.x
		int_b = vec_b.x
	
	var start_idx = random.randi_range(min(int_a, int_b),max(int_a, int_b))
	var output:Vector2i
	
	if vert:
		output = Vector2i(vec_a.x, start_idx)
	else:
		output = Vector2i(start_idx, vec_a.y)
	return output

func generate_room_passge(room_a : RoomStruct, room_b : RoomStruct)->bool:
	#no entry if already made a passage between these two rooms.. 
	if room_list.has_completed_passage(room_a.node_loc, room_b.node_loc):
		return false;
	room_list.add_completed_passage(room_a.node_loc, room_b.node_loc)
	
	#find closest wall between rooms, then delete walls and add passageway walls
	var a_to_b_direction:int=-1
	var b_to_a_direction:int=-1
	
	for dir_idx in range(0, room_a.direction_arr.size()-1):
		if room_a.direction_arr[dir_idx] == room_b:
			a_to_b_direction = dir_idx
			break
	
	for dir_idx in range(0, room_b.direction_arr.size()-1):
		if room_b.direction_arr[dir_idx] == room_a:
			b_to_a_direction = dir_idx
			break
	
	var start:Vector2i=_gen_room_passage_sort_helper(room_a, a_to_b_direction)
	var finish:Vector2i=_gen_room_passage_sort_helper(room_b, b_to_a_direction)
	#todo: make passage width a different value. this is prob gonna cause issues rn
	passage_cutter(room_a.room_appearance, start, finish, 3, is_horizontal_dir(a_to_b_direction), is_horizontal_dir(b_to_a_direction))
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

func generate(seed : int):
	if (generator_resource == null):
		return;
	var tm :TileMap = $WorldMap
	tm.tile_set = generator_resource.tile_set
	
	room_spacing = Vector2i(generator_resource.base_room_size_max, generator_resource.base_room_size_max)
	random = RandomNumberGenerator.new()
	random.seed = seed;
	
	#var val1 = random.randi_range(-10,0)
	#var val2 = random.randi_range(-10,0)
	#print(val1, val2)
	#print("get_cell_atlas_coords ", tm.get_cell_atlas_coords(0, Vector2i(val1, val2)))
	#print("get_cell_source_id ", tm.get_cell_source_id(0, Vector2i(val1, val2)))
	#print("get_cell_atlas_coords", tm.get_cell_atlas_coords(0, Vector2i(val1, val2)))
	#print("get_cell_atlas_coords", tm.get_cell_atlas_coords(0, Vector2i(val1, val2)))
	
	var numRooms :int= random.randi_range(generator_resource.base_number_of_rooms_min, generator_resource.base_number_of_rooms_max)
	
	room_list = RoomList.new()
	room_list.random = random;
	
	# root node will always be at max number of rooms * max number of rooms in order to ensure all rooms can fit in any linear direction.
	var root_node_loc := Vector2i(generator_resource.base_number_of_rooms_max, generator_resource.base_number_of_rooms_max);
	
	room_list.make_root_node(root_node_loc)
	var cur_num_rooms = 1
	while cur_num_rooms < numRooms:
		room_list.get_root().add_to_random_unfilled()
		cur_num_rooms += 1;
	
	#todo: make exit and enterance nodes a certain dist from each other.
	
	#make basic room layouts/positions, set up walls and floors
	for inner:Array[RoomStruct] in room_list.all:
		for room:RoomStruct in inner:
			if room == null:
				continue
			room.area = Vector2i(random.randi_range(generator_resource.base_room_size_min, generator_resource.base_room_size_max), random.randi_range(generator_resource.base_room_size_min, generator_resource.base_room_size_max))
			#make wiggle room area, then move it randomly within that.
			room.wiggled = room_spacing - room.area
			room.wiggled = Vector2i(random.randi_range(0, room.wiggled.x), random.randi_range(0, room.wiggled.y))
			loop_make_room_walls(room)
	
	#add additional passages between rooms
	if generator_resource.chance_add_passageway_between_neighbour_rooms_per_room > random.randf_range(0,1):
		for inner:Array[RoomStruct] in room_list.all:
			for room:RoomStruct in inner:
				if room == null:
					continue
				var dir_arr : Array[Vector2i];
				dir_arr.push_back(room.north_loc())	
				dir_arr.push_back(room.east_loc())
				dir_arr.push_back(room.south_loc())
				dir_arr.push_back(room.west_loc())
				if generator_resource.also_add_passageway_between_diagonal_neighbour_rooms:
					dir_arr.push_back(room.node_loc + move_north + move_east)
					dir_arr.push_back(room.node_loc + move_east + move_south)
					dir_arr.push_back(room.node_loc + move_south + move_west)
					dir_arr.push_back(room.node_loc + move_west + move_north)
				for loc_idx in range(0, dir_arr.size()-1):
					var loc:Vector2i=dir_arr[loc_idx]
					var found_room : RoomStruct = room_list.all[loc.x][loc.y]
					if found_room != null:
						#the direction detection here is kinda crap, but it will have to do for now..
						var dirs_from:Vector2i= get_two_nearest_directions(room.node_loc, found_room.node_loc)
						var dirs_to:Vector2i= get_two_nearest_directions(found_room.node_loc, room.node_loc)
						if loc_idx > 3:#diagonal case, need to try 4 different combinations of directions to see if one works.
							var link_dir_arr: Array = [dirs_from.x, dirs_to.x, dirs_from.y, dirs_to.y, dirs_from.x, dirs_to.y, dirs_from.y, dirs_to.x]
							for idx in range(0, 3):
								var idxp0 = 2*idx
								var idxp1 = idxp0+1
								if room_list.maybe_add_link_between(room, link_dir_arr[idxp0], found_room, link_dir_arr[idxp1]):
									break
						else:
							#basic direct adjacent link
							room_list.maybe_add_link_between(room, dirs_from.x, found_room, dirs_to.x)
							
				
	var root_room:RoomStruct = room_list.get_root()
	recurse_make_room_passages(root_room, root_room.node_loc)
	
	$Player.position = room_space_to_tile_map_space(root_node_loc)*128

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
