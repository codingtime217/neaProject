extends Node2D

var compound = "water"
var vector = Vector2(0,0) #starts as nothing, used for visualising flux atm
@export var temp = 293.15 #in kelvin
var thermal_energy = 10.0
var conductivity = 1.0 #in Wm^-1K^-1 a proportionality constant on thermal flux
var specificHeatCap = 100.0 #in KJ^-1kg^-1
var colour = Color(0,0,0)
var density = 1000.0 #kgm^-3
var mass = 0.0
const selfScene = preload("res://Scenes/tile.tscn")

#neyuron implementation plan, each tile has neutron cross section, asbrob chance and atomic mass in neutrons
#neutron crosssection is used to etermine if a collision occurs and the absorb chance and atomic mass are used to detemine the outcome of the collision
#if a neutron is absorbed, use fission chance to determine if it results in fission
#The actual neutron flux in each direaction is stored as average energy (eV), no. of neutrons and a flow direction
var neutronFlux = {"energy": 0.0, "no": 0.0}
var neutronFluxList  = {"up": neutronFlux.duplicate(),"down":neutronFlux.duplicate(),"left":neutronFlux.duplicate(),"right":neutronFlux.duplicate()}
var neutronCrossSection 
var specificActivity #decays per unit mass
var decayDistribution #lists what % is what type of decy
var absorbChance : float
var fissionChance : float
var atomicMass
@onready var button = $Button
var screen_size := Vector2(32,32)


static func newTile(pos : Vector2, mat : String, _args : Dictionary = {}):
	var tileInstance := selfScene.instantiate()
	var tileData = tileInstance.get_node(".")
	tileData.compound = mat
	tileData.position = pos
	tileData.setup(mat)
	return tileInstance

func _ready():
	button.texture_normal = load("res://materials/" + compound + ".tres")
	button.size = Vector2(16,16)

func get_variable_list() -> Array[Dictionary]: #will return an array of dicts of the properties, have first half be constants, 2nd half variables
	var constants : Dictionary
	var variables : Dictionary
	constants = {"conductivity" = conductivity,"specificHeatCap"  = specificHeatCap, "density" = density}
	variables = {"temperature" = temp}
	return [constants,variables]
	
func _update_properties(properties : Dictionary) -> void:
	print(properties)
	if properties.get("thermal_energy") != null:
		thermal_energy = properties.get("thermal_energy")
		temp = mass*specificHeatCap/thermal_energy
	elif properties.get("temperature") != null:
		temp = properties.get("temperature")
		thermal_energy = temp*mass*specificHeatCap
	pass



const materialsDict = {
	"water" : { #numbers from wikipidia, using numbers for 0*C, all units are per kg
		"conductivity" : 0.6089,
		"specificHeat" : 4184.0,
		"density" : 1000.0},
		
	"void" : {
		"conductivity" : 0.0,
		"specificHeat" : 0.0,
		"density" : 0.0
	}	
}



func _updateColour():#make colour chnage with temp, try and accurate blackbody
	pass




func setup(mat = "void"):
	var properties = materialsDict.get(mat,null)
	if properties == null:
		properties = materialsDict["water"]
	compound = mat
	conductivity = properties["conductivity"]
	specificHeatCap = properties["specificHeat"]
	density = properties["density"]
	mass = density / 1000.0 
	thermal_energy = temp*mass*specificHeatCap



#func _draw() -> void:
	
	#colour = Color(0,temp/150,0) #updates colour
	#draw_rect(Rect2(position, screen_size), colour) #draws cell
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	#queue_redraw()
	pass


 # Replace with function body.
