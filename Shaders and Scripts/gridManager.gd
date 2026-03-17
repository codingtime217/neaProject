extends Node2D

#inital values
var tileDimensions = Vector2i(16,16)
var tileScene = preload("res://Shaders and Scripts/tile.gd") #packed scene of a tile
var grid : Dictionary #will be used to store tiles
var selectedMat := "water"
signal freeGrid #used to get all tiles to remove from the tree
@onready var canvas = $CanvasLayer


func _link_signals(): #fetches the UI nodes and links the signals
	var UINode = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/cont/ItemList")
	UINode.item_selected.connect(changeSelected)
	var saveButton = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/save")
	saveButton.pressed.connect(save)
	var loadBUtton = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/load")
	loadBUtton.pressed.connect(load)	


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
		var localPos = _global_to_local(pos) #changed the coordinate to local
		if grid.get(pos) != null: #check for existing tile
			grid[pos].queue_free() #remove if there is already
		tile = tileScene.newTile(pos,mat) #add a new tile at the position
		grid[localPos] = tile #add it to the grid
	assert(tile != null,"no posMode Specified, no tile placed") #check we actually placed a tile
	canvas.add_child(tile) #place the tile as a child of canvas
	
func _global_to_local(global : Vector2) -> Vector2: #converts global coords to coords on the grid
	@warning_ignore("integer_division")
	var local = Vector2i(int(global.x)/16,int(global.y)/16)
	return local
	
func _local_to_global(local : Vector2i) -> Vector2: #converts coords on the grid to global coords
	@warning_ignore("integer_division")
	var global = Vector2i(local.x * 16,local.y * 16) + 1/2*tileDimensions
	return global


func _physics_process(_delta: float) -> void: #built in method, called as close to 60 times a second as possible
	var mousePos = get_local_mouse_position() #updates mouse position
	if Input.is_action_pressed("left_click"): #left click events place tiles
		var tilePos = _global_to_local(mousePos)
		_place_tile_("l",tilePos,selectedMat.to_lower())
	elif Input.is_action_pressed("right_click"): #right click removes
		var tilePos = _global_to_local(mousePos)
		if grid.get(tilePos) != null: #check theres actually a tile to remove
			grid[tilePos].queue_free() #remove it from existing as data
			grid.erase(tilePos)#then cleanup the dictionary so it does't contain it

func dataForm() -> Array: #used to convert the dictionary of tiles into an array based format used to pass data else where
	var tileKeyArray = dictToArrayOfKeys(grid) #calls something else to make the array
	var width = int(tileKeyArray["width"]) + 1 
	var dataArray = keysToData(cleanArray(tileKeyArray["minX"],width,tileKeyArray["array"]),tileKeyArray["minX"])
	var meta = metaData(width,dataArray)
	return [meta,dataArray] #meta contains a dict to convert indexes to tile materials and the width of the tile grid, dataArray contains an array of tile data 

func save() -> void:
	var dataArray = dataForm() #turn the data into an array
	var fileNameNode = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/simName")
	var fileName = fileNameNode.text + ".txt" #get the name to save it as
	var dataToWrite = JSON.stringify(dataArray) #turn the data into a json string
	writeToFile(fileName,dataToWrite) #call this to save the data
	
	
func load() -> void:
	var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd") #get the json loader
	var fileNameNode = get_node(^"/root/mainNode/Editor/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/simName")
	var fileName = fileNameNode.text + ".txt" #get the file name
	var data
	data = jsonLoader.loadingJsonFile(fileName) #load the file from JSON as a big object
	if data == null:
		data = jsonLoader.loadingJsonFile(fileName) #if it didn't work try again
	if data == null:
		return #if it defintly didn't work then don't bother
	
	#start getting data out of the compact form
	var width = int(data[0][0]["width"])
	var indexToMat = data[0][1]
	var bulkData = data[1]
	var j = 0
	var i = 0
	freeGrid.emit() #wipe the current tiles and grid
	grid.clear()
	while len(grid.keys()) < len(bulkData):
		var currentCell = bulkData[i + j*width] #iterate through the data
		var localCoord = Vector2(i,j) #keep track of which coordinate is should go to
		_place_tile_("l",localCoord,indexToMat[str(int(currentCell[0]))]) #make the tile
		grid[localCoord]._update_properties(currentCell[1]) #then update all of its variables to the stored value
		i += 1
		if i % width == 0: #update the coordinate to place at
			i = 0
			j +=1

func dictToArrayOfKeys(dict : Dictionary) -> Dictionary:
	var array := [[]]
	var maxX := 0 #small number
	var minX := 2**62 #largest singed 64 bit intger
	for i in dict.keys(): #goes though all the keys in order
		if i.x > maxX: #find max and mins to determine the width we need and how to later adjust the coordinate to have topleft be 0,0
			maxX = int(i.x)
		if i.x <= minX:
			minX = int(i.x)
		if array == [[]]:
			array[0].append(i) #if its empty just slap it in
		else:
			array = _insertItemToArrayOfKeys(array,i) #otherwise find the appropriate place
	var width = maxX-minX
	return {"minX" : minX,"width" : width, "array" : array} #return the array with the metaData of the minx and width
		
func _insertItemToArrayOfKeys(array : Array, item) -> Array:
	if item.y > array[-1][0].y: #put at the end if this is lower down than the others
		array.append([item])
		return array
	for j in len(array):#otherwise iterate through the array
		if item.y == array[j][0].y: #find row corresponding row if it exists
			for k in range(len(array[j])):
				if item.x < array[j][k].x: #find the right spot
							array[j].insert(k,item) #insert it there
							return array
			array[j].append(item) #or slap on the end
			return array
		elif item.y < array[j][0].y: #create the row if it doesnt
			array.insert(j,[item]) #and insert the item
			return array
	
	print("couldn't insert", item) #let me know if it didn't work
	return array	

func keysToData(keys : Array,minX : int) -> Array:
	var arrayForm = []
	for i in keys: #iterate through the array of keys
		if i == null: #ignore empty cells
			arrayForm.append(null) #make sure we don't lose them though
			continue
		var rawData = grid.get(i + Vector2(minX,0),null) #has to undo early transform as grid is global coords not position in grid
		var cleanData
		if rawData != null:
			cleanData = [rawData.compound,rawData.get_variable_list()[1]] #turn it into just the material and a dictionary of properties
		arrayForm.append(cleanData)#add it to the array
	return arrayForm #does what is says on the tin
	
func cleanArray (minX : int,width : int,keyArray : Array) -> Array: #cleans up the array so every row is [width] items long
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
	var matToIndex = {null : 0} #make two dictionaryes, one for material to index and one for vice versa
	var indexToMat = {0 : "void"}
	var j = 1
	for i in len(arrayOfTiles):
		if arrayOfTiles[i]== null: #if its blank add some filler
			arrayOfTiles[i]= [0,{"temperature" : 0}]
			continue
		var matFetch = matToIndex.get(arrayOfTiles[i][0], -1) #using -1 instead of null as null is used earlier
		if matFetch == -1: #it wasn't in the dictionary
			matToIndex[arrayOfTiles[i][0]] = j #so add it to the dictionary
			indexToMat[j] = arrayOfTiles[i][0] #and store the transformation
			arrayOfTiles[i][0] = j # then change the material in the array to the key used to find it
			j += 1
		elif matFetch != -1:
			arrayOfTiles[i][0] = matFetch #change the material in the array to the index 
	return indexToMat #return the dictionary to map back to properties
	
func writeToFile(fileName,content): #write a string to a file
	var file = FileAccess.open(fileName,FileAccess.WRITE)
	file.store_string(content)
