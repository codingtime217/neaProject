extends Node2D

var compound = "water"
var vector = Vector2(0,0) #starts as nothing, used for visualising flux atm
var temperature = 293.15 #in kelvin
var thermalEnergy = 10.0
var conductivity = 1.0 #in Wm^-1K^-1 a proportionality constant on thermal flux
var specificHeatCap = 100.0 #in KJ^-1kg^-1
var colour = Color(0,0,0)
var density = 1000.0 #kgm^-3
var mass = 0.0
const selfScene = preload("res://Scenes/tile.tscn")
var colourKeySetter
#neyuron implementation plan, each tile has neutron cross section, asbrob chance and atomic mass in neutrons
#neutron crosssection is used to etermine if a collision occurs and the absorb chance and atomic mass are used to detemine the outcome of the collision
#if a neutron is absorbed, use fission chance to determine if it results in fission
#The actual neutron flux in each direaction is stored as average energy (eV), no. of neutrons and a flow direction

var fissile = false
var thermalNeutronFlux := 0.0
var fastNeutronFlux := 0.0
var thermalCrossSection  : float # in barns
var fissileDensity = 0.0
var enrichment = 0.0
var drawMode = "static"
var atomDensity

var screen_size := Vector2(32,32)


@onready var button = $Button
@onready var overlay = $overlay

static func newTile(pos : Vector2, mat : String, drawModeIN = "static"):
	var tileInstance := selfScene.instantiate()
	var tileData = tileInstance.get_node(".")
	tileData.compound = mat
	tileData.position = pos
	tileData.drawMode = drawModeIN
	tileData.temperature = 235.15
	tileData.setup(mat)
	return tileInstance

func _ready():
	setup(compound)
	if drawMode == "static":
		button.texture_normal = load("res://materials/" + compound + ".tres")
	button.size = Vector2(16,16)

	var sim = get_node(^"/root/mainNode/Sim")
	if sim != null:
		sim.updatedGrid.connect(_updateColour)
	var editor = get_node("../gridManager")
	if editor != null:
		editor.freeGrid.connect(queue_free)

func get_variable_list() -> Array[Dictionary]: #will return an array of dicts of the properties, have first half be constants, 2nd half variables
	var constants : Dictionary
	var variables : Dictionary
	constants = materialsDict[compound]
	variables = {"thermalEnergy" = thermalEnergy,"temperature" = temperature}
	
	var nuclearData = {"enrichment" = enrichment,"fissileDensity" = fissileDensity,"thermalNeutronFlux" = thermalNeutronFlux, "fastNeutronFlux" = fastNeutronFlux}
	variables.merge(nuclearData)
	return [constants,variables]
	
func _update_properties(properties : Dictionary) -> void:
	for i in properties.keys():
		if get(i) != null:
			set(i,properties[i])
	if properties.get("thermalEnergy") != null:
		thermalEnergy = properties.get("thermalEnergy")
		temperature = thermalEnergy/(mass*specificHeatCap)
	elif properties.get("temperature") != null:
		temperature = properties.get("temperature")
		thermalEnergy = temperature*mass*specificHeatCap
	if properties.get("enrichment") != null and materialsDict[compound].get("fissile",false) == true:
		fissileDensity = atomDensity * (enrichment/100)
		pass

var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd")
var materialsDict = jsonLoader.loadingJsonFile("res://materials/materialsProperties.json")





func _draw():
	if drawMode != "static":
		draw_rect(Rect2(Vector2(0,0),Vector2(16,16)),colour)


func _updateColour(colours : Dictionary):#make colour chnage with temperature, try and accurate blackbody
	colours = colours.duplicate()
	drawMode = ""
	button.texture_normal = null
	if colours.get("mode", null) == "material":
		drawMode = "static"
		button.texture_normal = load("res://materials/" + compound + ".tres")
	elif colours.get("gradient", null) != null:
		var grad = colours["gradient"]
		var maxV = colours["max"]
		var minV = colours["min"]
		var key = colours["mode"]
		if key == "thermal energy":
			key = "thermalEnergy"
		colour = grad.sample((get(key)-minV)/(maxV-minV))	
	queue_redraw()

func setup(mat = "void"):
	var properties = materialsDict.get(mat,null)
	if properties == null:
		properties = materialsDict["water"]
	compound = mat
	conductivity = properties["conductivity"]
	specificHeatCap = properties["specificHeat"]
	density = properties["density"]
	mass = density / 1000.0 
	fissile = properties["fissile"]
	atomDensity = properties.get("atomDensity",0)
	thermalCrossSection = properties.get("thermalCrossSection",0)
	thermalEnergy = temperature*mass*specificHeatCap
	if properties.get("fissile",false) == true:
		thermalNeutronFlux = 1E24
		fastNeutronFlux = 1E24

func _on_button_toggled(toggled_on: bool) -> void:
	overlay.visible = toggled_on
	pass # Replace with function body.
