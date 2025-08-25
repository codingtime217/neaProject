extends Node2D
@export var vector = Vector2(0,0) #starts as nothing, used for visualising flux atm
@export var temp = 0.0 #in kelvin
@export var conductivity = 1.0 #in Wm^-1K^-1 a proportionality constant on thermal flux
@export var specficHeatCap = 100.0 #in KJ^-1kg^-1
@export var colour = Color(0,0,0)
@export var density = 1000.0 #kgm^-3
var dimensions = Vector2(32,32)
var offset

func _ready():
	offset = get_viewport_rect().size/2

const materialsDict = {
	"water" : { #numbers from wikipidia, using numbers for 0*C
		"conductivity" : 0.6089,
		"specificHeat" : 4184.0,
		"density" : 1000.0}	
}


func _updateColour():#make colour chnage with temp, try and accurate blackbody
	pass

func initiate(mat = null,pos = Vector2(0,0)):
	self.position = (pos-Vector2(0.5,0.5))*dimensions + offset
	var properties = materialsDict.get(mat,null)
	if properties == null:
		properties = materialsDict["water"]
	conductivity = properties["conductivity"]
	specficHeatCap = properties["specificHeat"]
	density = properties["density"]



func _draw() -> void:
	var screen_size := Vector2(32,32)
	draw_rect(Rect2(global_position, screen_size), colour)
	#draw_line((global_position,(global_position+Vector2(16,16))+vector,Color(1,1,1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	initiate("water")
