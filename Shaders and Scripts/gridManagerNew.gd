extends Node
#tis will be a combo of the other methods, ie instnacing nodes + dict/array for storing
#but use tilemap stuff to lock position to increments

@export var tileDimensions = Vector2i(16,16)
var tileScene = preload("res://Shaders and Scripts/tile.gd")
var grid : Dictionary

func _place_tile_(posMode : String, position : Vector2, material) -> void:
	var tile
	if posMode == "l":
		tile = tileScene.newTile(_local_to_global(position),material)
		grid[position] = tile
	elif posMode == "g":
		tile = tileScene.newTile(position,material)
		grid[_global_to_local(position)] = tile
	assert(tile != null,"no posMode Specified, no tile placed")
	add_child(tile)
	
	
func _global_to_local(global : Vector2) -> Vector2:
	@warning_ignore("integer_division")
	var local = Vector2i(int(global.x)/16,int(global.y)/16)
	return local
	
func _local_to_global(local : Vector2i):
	@warning_ignore("integer_division")
	var global =local * tileDimensions + 1/2*tileDimensions
	return global

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_place_tile_("g",Vector2(100,100),"water")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
