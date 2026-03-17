extends Node2D

var compound = "water"
var temperature = 293.15 #in kelvin
var thermalEnergy = 10.0 #in joules
var conductivity = 1.0 #in Wm^-1K^-1 a proportionality constant on thermal flux
var specificHeatCap = 100.0 #in KJ^-1kg^-1
var colour = Color(0,0,0)
var density = 1000.0 #kgm^-3
var mass = 0.0


var fissile := false
var thermalNeutronFlux := 0.0
var fastNeutronFlux := 0.0
var thermalCrossSection  : float # in barns
var fissileDensity := 0.0
var enrichment := 0.0
var drawMode := "static"
var atomDensity : float

var screen_size := Vector2(32,32)

const selfScene = preload("res://Scenes/tile.tscn")
@onready var button = $Button
@onready var overlay = $overlay

var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd")
var materialsDict = jsonLoader.loadingJsonFile("res://materials/materialsProperties.json")


static func newTile(pos : Vector2, mat : String, drawModeIN = "static"): #used to make new tiles and do inital setup without adding to the scene tree yet
	var tileInstance := selfScene.instantiate() #instantiate self
	var tileData = tileInstance.get_node(".") #grab the tile node from it
	tileData.compound = mat #set the essential values
	tileData.position = pos
	tileData.drawMode = drawModeIN
	tileData.temperature = 235.15
	tileData.setup(mat) #get it to the do the other setup
	return tileInstance #return the scene instance to where it was created

func _ready():
	setup(compound) #redo setup if we haven't
	if drawMode == "static": 
		button.texture_normal = load("res://materials/" + compound + ".tres") #not doing colour coding so give the button a texture to display
	button.size = Vector2(16,16) #make sure the button lines up

	var sim = get_node(^"/root/mainNode/Sim") #try and get the sim node
	if sim != null: #this only evaluates true if the sim scene is active
		sim.updatedGrid.connect(_updateColour) #therefore connect to the colour coding
	var editor = get_node("../gridManager")
	if editor != null: #this will only be true if we are in the editor
		editor.freeGrid.connect(queue_free) #so connect to the grid wipeing signal

func get_variable_list() -> Array[Dictionary]: #will return an array of dicts of the properties, have first half be constants, 2nd half variables
	var constants : Dictionary
	var variables : Dictionary
	constants = materialsDict[compound]
	variables = {"thermalEnergy" = thermalEnergy,
	"temperature" = temperature,
	"enrichment" = enrichment,
	"fissileDensity" = fissileDensity,
	"thermalNeutronFlux" = thermalNeutronFlux,
	 "fastNeutronFlux" = fastNeutronFlux}
	return [constants,variables]
	
func _update_properties(properties : Dictionary) -> void: #takes in a dictionary of properties
	for i in properties.keys(): #for each property in the dict
		if get(i) != null: #check it is a tile property
			set(i,properties[i])#if it is then set the property to the value in the dictionary
			
	#if one of the properties another depends on changed then change the linked property
	if properties.get("thermalEnergy") != null:
		thermalEnergy = properties.get("thermalEnergy")
		temperature = thermalEnergy/(mass*specificHeatCap)
	elif properties.get("temperature") != null:
		temperature = properties.get("temperature")
		thermalEnergy = temperature*mass*specificHeatCap
	if properties.get("enrichment") != null and materialsDict[compound].get("fissile",false) == true:
		fissileDensity = atomDensity * (enrichment/100)

func _draw():
	if drawMode != "static": #if we are colour coding
		draw_rect(Rect2(Vector2(0,0),Vector2(16,16)),colour) #draw a rectangle in the right place of the colour


func _updateColour(colours : Dictionary):#make colour change with temperature, colours contains a gradient, the min and max values and what property to colour code one
	colours = colours.duplicate()
	drawMode = ""
	button.texture_normal = null #make sure the texture is removed so that isn't rendered
	if colours.get("mode", null) == "material": #if were coded by material then go back to this
		drawMode = "static"
		button.texture_normal = load("res://materials/" + compound + ".tres")
	elif colours.get("gradient", null) != null:
		var grad = colours["gradient"]
		var maxV = colours["max"]
		var minV = colours["min"]
		var key = colours["mode"]
		if key == "thermal energy":
			key = "thermalEnergy" #remove the space if its there
		colour = grad.sample((get(key)-minV)/(maxV-minV))	#sample the colour from between min and max where the property coding by falls
	queue_redraw() #redraw with the new colour

func setup(mat = "void"):
	var properties = materialsDict.get(mat,null) #get all the properties of the material
	if properties == null: #if the material didn't work/isn't in the database
		properties = materialsDict["water"] #make the tile water
		
	#set the properties to the correct values
	compound = mat
	conductivity = properties["conductivity"]
	specificHeatCap = properties["specificHeat"]
	density = properties["density"]
	mass = density / 1000.0 
	fissile = properties["fissile"]
	atomDensity = properties.get("atomDensity",0)
	thermalCrossSection = properties.get("thermalCrossSection",0)
	thermalEnergy = temperature*mass*specificHeatCap
	#if fissile add 10^24 thermal and fast neutron flux
	if properties.get("fissile",false) == true:
		thermalNeutronFlux = 1E24
		fastNeutronFlux = 1E24

func _on_button_toggled(toggled_on: bool) -> void: #if the tile is selected/unslected
	overlay.visible = toggled_on #turn on/off the overlay
