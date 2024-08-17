extends Resource
class_name EnemySetting

@export var enemy_name:String
@export var enemy_type:PackedScene

#every time a new level is generated, this value is multiplied against the level number, then added to the spawn_chance_base
#then each enemy type chance is added together. This value is used to randomize between 0 to that number, and if the number is 
#this enemy type, then this type is spawned.

#negative values are usable, and encouraged for enemies who should only show up early game.
@export var spawn_chance_per_level:int=0
@export var spawn_chance_base:int=100

#notes for us developers to see.
@export_multiline var developer_notes:String
