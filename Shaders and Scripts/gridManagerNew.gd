extends Node2D
#tis will be a combo of the other methods, ie instnacing nodes + dict/array for storing
#but use tilemap stuff to lock position to increments

@export var tileDimensions = Vector2i(16,16)
var tileScene = preload("res://Shaders and Scripts/tile.gd")
var grid : Dictionary
var selectedIndex
var canvas


func _link_signals(): #fetches the UI nodes and links the signals
	var UINode = get_node(^"/root/UIEditor/CanvasLayer/cont/ItemList")
	UINode.item_selected.connect(selectedMat)
	var saveButton = get_node(^"/root/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/save")
	saveButton.pressed.connect(save)

	


func selectedMat(index : int):#updates which material is currently selected
	selectedIndex = index
	
func selectToMat():
	var matList = get_node(^"/root/UIEditor/CanvasLayer/cont/ItemList")
	return matList.get_language(selectedIndex).lower()

func _place_tile_(posMode : String, pos : Vector2, mat) -> void: #places a tile in the specified position
	var tile
	if posMode == "l": #if the coordinate is local do this
		if grid.get(pos) != null: #checks if a tile is already there
			grid[pos].free() #removes the tile if it is there
		tile = tileScene.newTile(_local_to_global(pos),mat) #make the tile
		grid[pos] = tile #put it in the dict
	elif posMode == "g": #if the coord is global do this
		var localPos = _global_to_local(pos)
		if grid.get(pos) != null:
			grid[pos].queue_free()
		tile = tileScene.newTile(pos,mat)
		grid[localPos] = tile
	assert(tile != null,"no posMode Specified, no tile placed") #check we actually placed a tile
	canvas.add_child(tile) #place the tile as a child
	
func _global_to_local(global : Vector2) -> Vector2: #converts global coords to coords on the grid
	@warning_ignore("integer_division")
	var local = Vector2i(int(global.x)/16,int(global.y)/16)
	return local
	
func _local_to_global(local : Vector2i) -> Vector2: #converts coords on the grid to global coords
	@warning_ignore("integer_division")
	var global = Vector2i(local.x * 16,local.y*16) + 1/2*tileDimensions
	return global

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	canvas = get_node("CanvasLayer")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mousePos = get_local_mouse_position() #updates mouse position
	if Input.is_action_pressed("left_click"): #left click events place tiles
		var tilePos = _global_to_local(mousePos)
		_place_tile_("l",tilePos,"water")
	elif Input.is_action_pressed("right_click"): #right click removes
		var tilePos = _global_to_local(mousePos)
		if grid.get(tilePos) != null: #check theres actually a tile to remove
			grid[tilePos].queue_free()
	pass


func save() -> void:
	#use some stuff to turn the tileMap into a big string array
	var fileNameNode = get_node(^"/root/UIEditor/PanelContainer/VBoxContainer/HBoxContainer/simName")
	var fileName = fileNameNode.text + ".txt"
	if fileName == "":
		fileName = "sim.txt"
	print(fileName)
	writeToFile(fileName,metaData())
	
	
func convertToData() -> String: #will convert the grid Dict to a string of data to write to a file
	var cellData : String
	var cell : TileData
	return ""
	
func metaData() -> String: #encode the dimesnions of the grid + other info to be placed at the start of the file

	
	return "hello"
	
	
func writeToFile(fileName,content): #write a string to a file
	var file = FileAccess.open(fileName,FileAccess.WRITE)
	file.store_string(content)
