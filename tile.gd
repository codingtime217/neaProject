extends Node2D
var compound = "water"
@export var vector = Vector2(0,0) #starts as nothing, used for visualising flux atm
@export var temp = 0.0 #in kelvin
@export var conductivity = 1.0 #in Wm^-1K^-1 a proportionality constant on thermal flux
@export var specificHeatCap = 100.0 #in KJ^-1kg^-1
@export var colour = Color(0,0,0)
@export var density = 1000.0 #kgm^-3
@export var mass = 0.0
var screen_size := Vector2(32,32)

#func _ready():
	#offset = get_viewport_rect().size/2

const materialsDict = {
	"water" : { #numbers from wikipidia, using numbers for 0*C
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




func setup(mat = "void",pos = Vector2(0,0)):
	position = pos
	var properties = materialsDict.get(mat,null)
	if properties == null:
		properties = materialsDict["water"]
	compound = mat
	
	temp = pos.x/16 *10 + pos.y/16 *5
	conductivity = properties["conductivity"]
	specificHeatCap = properties["specificHeat"]
	density = properties["density"]
	mass = density / 1000.0  #as volume is 1/1000 m^3
	colour = Color(0,temp/200,0)	
	



func _draw() -> void:
	
	colour = Color(0,temp/200,0) #updates colour
	draw_rect(Rect2(position, screen_size), colour) #draws cell
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#queue_redraw()
	pass
