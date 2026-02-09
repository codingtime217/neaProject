extends Node
#tis will be a combo of the other methods, ie instnacing nodes + dict/array for storing
#but use tilemap stuff to lock position to increments

@export var tileDimensions = Vector2i(16,16)
var tileScene = preload("res://Shaders and Scripts/tile.gd")
var grid : Dictionary

func _place_tile_(localposition : Vector2, material) -> void:
	var tile = tileScene.newTile(_local_to_global(localposition),material)
	add_child(tile)
	grid[localposition] = tile
	
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
	_place_tile_(Vector2(100,100),"water")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
