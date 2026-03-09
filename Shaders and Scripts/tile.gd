extends Node2D

var compound = "water"
var vector = Vector2(0,0) #starts as nothing, used for visualising flux atm
var temperature = 293.15 #in kelvin
var thermal_energy = 10.0
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
var neutronFlux = {"energy": 0.0, "no": 0.0}
var neutronFluxList  = {"up": neutronFlux.duplicate(),"down":neutronFlux.duplicate(),"left":neutronFlux.duplicate(),"right":neutronFlux.duplicate()}
var neutronCrossSection 
var fissileDensity = 0.0
var enrichment = 0.0
var specificActivity #decays per unit mass
var decayDistribution #lists what % is what type of decy
var absorbChance : float
var fissionChance : float
var atomicMass
var drawMode = "static"


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
	if drawMode == "static":
		button.texture_normal = load("res://materials/" + compound + ".tres")
	button.size = Vector2(16,16)
	var sim = get_node(^"/root/mainNode/Sim")
	if sim != null:
		sim.updatedGrid.connect(_updateColour)
	

func get_variable_list() -> Array[Dictionary]: #will return an array of dicts of the properties, have first half be constants, 2nd half variables
	var constants : Dictionary
	var variables : Dictionary
	constants = {"conductivity" = conductivity,"specificHeatCap"  = specificHeatCap, "density" = density}
	variables = {"temperature" = temperature}
	if fissile == true:
		var nuclearData = {"enrichment" = enrichment}
		variables.merge(nuclearData)
	return [constants,variables]
	
func _update_properties(properties : Dictionary) -> void:
	for i in properties.keys():
		if get(i) != null:
			set(i,properties[i])
	if properties.get("thermal_energy") != null:
		thermal_energy = properties.get("thermal_energy")
		temperature = mass*specificHeatCap/thermal_energy
	elif properties.get("temperature") != null:
		temperature = properties.get("temperature")
		thermal_energy = temperature*mass*specificHeatCap
	if properties.get("enrichment") != null:
		#needs to change value of fissile density
		pass

func loadingJsonFile(path : String):
	var file = FileAccess.open(path,FileAccess.READ)
	var text = file.get_as_text()
	var json_result = JSON.parse_string(text)
	return json_result


var materialsDictThermal = loadingJsonFile("res://materials/materialsProperties.json")

const materialsDictThermaltwo = {
	"water" : { #numbers from wikipidia, using numbers for 0*C, all units are per kg
		"conductivity" : 0.6089,
		"specificHeat" : 4184.0,
		"density" : 1000.0}, #
		
	"void" : {
		"conductivity" : 0.0,
		"specificHeat" : 0.0,
		"density" : 0.0
	},
	"uranium" : {
		"conductivity" : 27.5,
		"specificHeat" : 116.225,
		"density" : 19050.0
	}
}

const materialsDictNuclear = { #for nuclear properties
	"void" : {},
	"water" : {}
}


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
		var max = colours["max"]
		var min = colours["min"]
		var key = colours["mode"]
		if key == "thermal energy":
			key = "thermal_energy"
		colour = grad.sample((get(key)-min)/(max-min))	
	queue_redraw()




func setup(mat = "void"):
	var properties = materialsDictThermal.get(mat,null)
	if properties == null:
		properties = materialsDictThermal["water"]
	compound = mat
	conductivity = properties["conductivity"]
	specificHeatCap = properties["specificHeat"]
	density = properties["density"]
	mass = density / 1000.0 
	fissile = properties["fissile"]
	thermal_energy = temperature*mass*specificHeatCap


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	#queue_redraw()
	pass


 # Replace with function body.

func _on_button_toggled(toggled_on: bool) -> void:
	overlay.visible = toggled_on
	pass # Replace with function body.
