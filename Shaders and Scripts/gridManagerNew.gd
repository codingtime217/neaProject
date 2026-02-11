extends Node2D
#tis will be a combo of the other methods, ie instnacing nodes + dict/array for storing
#but use tilemap stuff to lock position to increments

@export var tileDimensions = Vector2i(16,16)
var tileScene = preload("res://Shaders and Scripts/tile.gd")
var grid : Dictionary
var selectedIndex

func _link_signals():
	var UINode = get_node(^"/root/UIEditor/CanvasLayer/cont/ItemList")
	UINode.item_selected.connect(selected)
	var saveButton = get_node(^"/root/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/save")
	saveButton.pressed.connect(save)
	

func save():
	pass #for saving stuff

func selected(index : int):
	selectedIndex = index
	
	
func selectToMat():
	var matList = get_node(^"/root/UIEditor/CanvasLayer/cont/ItemList")
	return matList.get_language(selectedIndex).lower()

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
	var mousePos = get_local_mouse_position()
	if Input.is_action_pressed("left_click"):
		var tilePos = _local_to_global(mousePos)
		
	elif Input.is_action_pressed("right_click"):
		var tilePos = _local_to_global(mousePos)
		grid[tilePos] = null
	pass
