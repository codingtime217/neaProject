extends Node2D
var UI = preload("res://Scenes/UISim.tscn")
var UIinstance #used to store the ui
var dataGrid : Dictionary #tiles as a dict where the key is the local position of the tile
var dataArray : Array #array of tile data
var tileDimensions = Vector2(16,16)
var width : int #width of the grid
var matDict : Dictionary #stores the material dict
var keyToMat : Dictionary #stores the material index to material relationship
var thermShader #thermal node
var nukeShader #nuclear node
var simData #used for initial setup
var tileScene = preload("res://Shaders and Scripts/tile.gd") #packed tile scene
var tempRange = Range.new() #used to store the range of temperatures for creating the colour key
var colourKeys :Dictionary
var colourKeySource #used to store the node which contains the colour key
signal loaded(runButton) #used for linking button to main node
signal updatedGrid(colourData : Dictionary) #used to get tiles and such to update their colour


func _ready() -> void:
	tempRange.min_value = 231 #arbitary staring value
	UIinstance = UI.instantiate()
	add_child(UIinstance) #get the UI into the scene tree
	colourKeySource = get_node("UISim/CanvasLayer/DrawModes") #get the colour key stuff
	colourKeySource.colourMode.connect(drawUpdate) #link the singals
	loaded.emit(UIinstance.get_node("CanvasLayer/SpeedOptions/HBoxContainer/Halt")) #link the stop button to main


func simDataSetup(): #setup the data
	dataArray = simData[1] #seperate out the tile data array
	thermShader = $thermal #get these storing the relevant nodes
	nukeShader = $nuclear
	width = simData[0][0]["width"] #seperate out the width and key to Mat 
	keyToMat = simData[0][1]
	thermShader.dataSetup(simData) #get the shaders to do their own setup
	thermShader.shaderSetup()
	nukeShader.dataSetup(simData)
	nukeShader.setup()


func _local_to_global(local : Vector2i) -> Vector2: #converts coords on the grid to global coords - copied from editor/gridManager
	@warning_ignore("integer_division")
	var global = Vector2i(local.x * 16,local.y * 16) + 1/2*tileDimensions
	return global
	
func updateDataArray(newDataArray : Array): #this will follow the data format of simData
	for i in range(0,len(newDataArray)): #go through the data array
		for j in newDataArray[i][1].keys():
			dataArray[i][1].erase("temperature") #remove temp and enrichment if they are still there
			dataArray[i][1].erase("enrichment") #this prevents some problems from them causing data overwrites
			dataArray[i][1][j] = newDataArray[i][1][j] #update the data
	
	
	
func _process(_delta: float) -> void: #call the two shaders in sequence then idk
	thermShader._runShader() #first run the thermal shader
	var currentData = thermShader.returnOutput()
	updateDataArray(currentData) #use the output to update the data array
	nukeShader.updateInput(dataArray) #update the nuke input
	nukeShader._runShader() #run the nuclear shader
	currentData = nukeShader.returnOutput()
	updateDataArray(currentData) #update the array based on the output
	thermShader.updateInput(dataArray) #update the thermal shader input
	var dictData = toDictForm(dataArray) #conver the data array into a dict of tile local coord : data
	updateGrid(dictData) #update all the tile objects
	updatedGrid.emit(colourKeys) #update the colours and such
	
func drawUpdate(data : Dictionary) -> void: #forward the signal to the tiles
	colourKeys = data
	updatedGrid.emit(colourKeys)
	
func updateGrid(data : Dictionary) -> void: #goes through the data 
	for i in data.keys():
		var tile = dataGrid.get(i,null)
		if data[i]["mat"] == 0: #if its void ignore it
			continue
		if tile == null: #if the tile isn't already there
			dataGrid[i] = newTile(data[i],i) #then make it
			add_child(dataGrid[i])
		else:
			#if it is then update its values
			dataGrid[i]._update_properties(data[i])
		#keep the range of min and max temp accurate
		if dataGrid[i]["temperature"] > tempRange.max_value:
			tempRange.max_value = dataGrid[i]["temperature"]
		elif dataGrid[i]["temperature"] < tempRange.min_value:
			tempRange.min_value = dataGrid[i]["temperature"]

func newTile(values,pos): #makes a new tile
	var tilePosition = _local_to_global(pos)
	var new_tile = tileScene.newTile(tilePosition,keyToMat[values["mat"]],"dynamic") #not static as drawing with colour code
	new_tile._update_properties(values)
	return new_tile

func toDictForm(data : Array, _type = "therm") -> Dictionary: #converts the data array to a dict
	var currentCord = Vector2(0,0)
	var i = 0
	var newDict = {}
	@warning_ignore("integer_division")
	while i < len(data):
		var currentCellDict = {"mat" : data[i][0]}
		currentCellDict.merge(data[i][1]) #merge the material and other info
		newDict[currentCord] = currentCellDict #then set key to the data for there 
		i +=1
		if i % width == 0: #iterate the coords
			currentCord.y += 1
			currentCord.x = 0
		else:
			currentCord.x += 1
	return newDict
