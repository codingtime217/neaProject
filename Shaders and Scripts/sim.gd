extends Node2D
var UI = preload("res://Scenes/UISim.tscn")
var UIinstance
var dataGrid : Dictionary
var dataArray : Array
var tileDimensions = Vector2(16,16)
var width : int
var matDict : Dictionary
var keyToMat : Dictionary
var thermShader
var nukeShader
var simData
var tileScene = preload("res://Shaders and Scripts/tile.gd")
var tempRange = Range.new()
var colourKeys :Dictionary
var colourKeySource
signal loaded(runButton)
signal updatedGrid(colourData : Dictionary)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tempRange.min_value = 231
	UIinstance = UI.instantiate()
	add_child(UIinstance)
	colourKeySource = get_node("UISim/CanvasLayer/DrawModes")
	colourKeySource.colourMode.connect(drawUpdate)
	loaded.emit(UIinstance.get_node("CanvasLayer/SpeedOptions/HBoxContainer/Halt"))
	pass # Replace with function body.


func simDataSetup():
	dataArray = simData[1]
	thermShader = $thermal
	nukeShader = $nuclear
	width = simData[0][0]["width"]
	keyToMat = simData[0][1]
	thermShader.dataSetup(simData)
	thermShader.shaderSetup()
	nukeShader.dataSetup(simData)
	nukeShader.setup()


func _local_to_global(local : Vector2i) -> Vector2: #converts coords on the grid to global coords
	@warning_ignore("integer_division")
	var global = Vector2i(local.x * 16,local.y * 16) + 1/2*tileDimensions
	return global
	
func updateDataArray(newDataArray : Array): #this will follow the data format of simData
	for i in range(0,len(newDataArray)):
		for j in newDataArray[i][1].keys():
			dataArray[i][1].erase("temperature")
			dataArray[i][1][j] = newDataArray[i][1][j]
	pass
	
	
	
func _process(_delta: float) -> void: #call the two shaders in sequence then idk
	thermShader._runShader() #this won't work, i need a universal to change them back into the universal format for this to work
	var currentData = thermShader.returnOutput()
	updateDataArray(currentData)
	nukeShader.updateInput(dataArray)
	nukeShader._runShader() 
	currentData = nukeShader.returnOutput()
	updateDataArray(currentData)
	thermShader.updateInput(dataArray)
	var dictData = toDictForm(dataArray)
	updateGrid(dictData)
	updatedGrid.emit(colourKeys)
	
func drawUpdate(data : Dictionary) -> void:
	colourKeys = data
	updatedGrid.emit(colourKeys)
	
func updateGrid(data : Dictionary) -> void:
	for i in data.keys():
		var tile = dataGrid.get(i,null)
		if data[i]["mat"] == 0:
			continue
		if tile == null:
			dataGrid[i] = newTile(data[i],i)
			add_child(dataGrid[i])
		else:
			data[i].erase("temperature")
			dataGrid[i]._update_properties(data[i])
		if dataGrid[i]["temperature"] > tempRange.max_value:
			tempRange.max_value = dataGrid[i]["temperature"]
		elif dataGrid[i]["temperature"] < tempRange.min_value:
			tempRange.min_value = dataGrid[i]["temperature"]

func newTile(values,pos):
	var tilePosition = _local_to_global(pos)
	var new_tile = tileScene.newTile(tilePosition,keyToMat[values["mat"]],"dynamic")
	new_tile._update_properties(values)
	return new_tile

func toDictForm(data : Array, _type = "therm") -> Dictionary:
	var currentCord = Vector2(0,0)
	var i = 0
	var newDict = {}
	@warning_ignore("integer_division")
	while i < len(data):
		var currentCellDict = {"mat" : data[i][0]}
		currentCellDict.merge(data[i][1])
		newDict[currentCord] = currentCellDict
		i +=1
		if i % width == 0:
			currentCord.y += 1
			currentCord.x = 0
		else:
			currentCord.x += 1
	return newDict
