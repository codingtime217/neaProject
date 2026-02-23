extends Node2D
#tis will be a combo of the other methods, ie instnacing nodes + dict/array for storing
#but use tilemap stuff to lock position to increments

@export var tileDimensions = Vector2i(16,16)
var tileScene = preload("res://Shaders and Scripts/tile.gd")
var grid : Dictionary
var selectedMat := "water"
@onready var canvas = $CanvasLayer


func _link_signals(): #fetches the UI nodes and links the signals
	var UINode = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/cont/ItemList")
	UINode.item_selected.connect(changeSelected)
	var saveButton = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/save")
	saveButton.pressed.connect(save)

	


func changeSelected(index : int):#updates which material is currently selected
	var list = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/cont/ItemList")
	selectedMat = list.get_item_text(index)
	


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
	var global = Vector2i(local.x * 16,local.y * 16) + 1/2*tileDimensions
	return global

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mousePos = get_local_mouse_position() #updates mouse position
	if Input.is_action_pressed("left_click"): #left click events place tiles
		var tilePos = _global_to_local(mousePos)
		_place_tile_("l",tilePos,selectedMat.to_lower())
	elif Input.is_action_pressed("right_click"): #right click removes
		var tilePos = _global_to_local(mousePos)
		if grid.get(tilePos) != null: #check theres actually a tile to remove
			grid[tilePos].queue_free()
			grid.erase(tilePos)
	pass

func dataForm() -> Array:
	var tileKeyArray = dictToArrayOfKeys(grid)
	var width = int(tileKeyArray["width"]) + 1
	var dataArray = keysToData(cleanArray(tileKeyArray["minX"],width,tileKeyArray["array"]),tileKeyArray["minX"])
	var meta = metaData(width,dataArray)
	return [meta,dataArray]

func save() -> void:
	var dataArray = dataForm()
	#use some stuff to turn the tileMap into a big string array
	var fileNameNode = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/simName")
	var fileName = fileNameNode.text + ".txt"
	var metaInfo = str(dataArray[0][0]) + "\n" + str(dataArray[0][1]) + "\n"
	if fileName == "":
		fileName = "sim.txt"
	var dataToWrite = ""
	for i in dataArray[1]:
		dataToWrite = dataToWrite + str(i) + "\n"
	writeToFile(fileName,metaInfo + dataToWrite)
	
func dictToArrayOfKeys(dict : Dictionary) -> Dictionary:
	var array := [[]]
	var maxX := 0 #small number
	var minX := 2**62 #largest singed 64 bit intger
	for i in dict.keys(): #goes though all the keys in order
		if i.x > maxX: #find max and mins to determine the width we need
			maxX = int(i.x)
		if i.x <= minX:
			minX = int(i.x)
		if array == [[]]:
			array[0].append(i) #if its empty just slap it in
		else:
			array = _insertItemToArrayOfKeys(array,i) #otherwise find the appropriate place
	var width = maxX-minX

	return {"minX" : minX,"width" : width, "array" : array} #return with metadata
		
func _insertItemToArrayOfKeys(array : Array, item) -> Array:
	if item.y > array[-1][0].y: #put at the end if appropriate
		array.append([item])
		return array
	for j in len(array):
		if item.y == array[j][0].y: #find row if it exists
			for k in range(len(array[j])):
				if item.x < array[j][k].x: #find the right spot
							array[j].insert(k,item)
							return array
			array[j].append(item) #or slap on the end
			return array
		elif item.y < array[j][0].y: #insert the row if it doesnt
			array.insert(j,[item])
			return array
	
	print("couldn't insert", item) #let me know if it didn't work
	return array	

func keysToData(keys : Array,minX : int) -> Array:
	var arrayForm = []
	for i in keys:
		if i == null: #ignore empty cells
			arrayForm.append(null) #make sure we don't lose them though
			continue
		var rawData = grid.get(i + Vector2(minX,0),null) #has to undo early transform as grid is global coords not position in grid
		var cleanData
		if rawData != null:
			cleanData = [rawData.compound,rawData.get_variable_list()[1]] 
		arrayForm.append(cleanData)
	return arrayForm #does what is says on the tin
	
func cleanArray (minX : int,width : int,keyArray : Array) -> Array: #cleans up the array so every part covers the whole width
	var cleanedArray = []
	for i in keyArray:
		i.resize(width) #make all rows the same width
		for j in range(1,width+1): #starrt from the back to avoid overwriting earlier changes
			var element = i[width-j]
			if element == null: #if its null skip
				continue
			else:
				element.x -= minX #transfomr x position to relative to furthest left tile
				var temp = element #temp variable for storage
				i[width-j] = null #delete current position
				i[temp.x] = temp #make index and x local line up
		cleanedArray = cleanedArray + i #turn it into a 1d array
	return cleanedArray
	
func metaData(width : int,arrayOfTiles : Array) -> Array: #encode the dimesnions of the grid + other info to be placed at the start of the file
	var metInfo = {"width" : width}
	var matDict = compressMaterials(arrayOfTiles) #get the compressed material form
	
	return [metInfo,matDict]
	
func compressMaterials(arrayOfTiles : Array) -> Dictionary: #creates a dictionary that maps a value to the material name
	var matToIndex = {null : 0}
	var indexToMat = {0 : "void"}
	var j = 1
	for i in len(arrayOfTiles):
		if arrayOfTiles[i]== null:
			arrayOfTiles[i]= [0,{"temperature" : 0}]
			continue
		var matFetch = matToIndex.get(arrayOfTiles[i][0], -1) #using -1 instead of null 
		if matFetch == -1:
			matToIndex[arrayOfTiles[i][0]] = j
			indexToMat[j] = arrayOfTiles[i][0]
			arrayOfTiles[i][0] = j #change the material in the array to the key used to find it
			j += 1
		elif matFetch != null:
			arrayOfTiles[i][0] = matFetch
	return indexToMat #return the dictionary to map back to properties
	
func writeToFile(fileName,content): #write a string to a file
	var file = FileAccess.open(fileName,FileAccess.WRITE)
	file.store_string(content)
