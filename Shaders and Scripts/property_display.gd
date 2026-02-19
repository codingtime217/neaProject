extends Control


var parent : Node
var label : String
var value
var mat : String
@onready var labelBox = $propertyLabel
@onready var valueBox = $propertyData

const units :=  {"conductivity" : " (W/mK)", "specificHeatCap" : " (J/kgK)", "density" : " (kg/m^3)"}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_node("../..")
	parent.connect("freeDisplays",queue_free)
	mat = parent.mat
	labelBox.text = cleanup(label)
	valueBox.text = str(value)
	pass # Replace with function body.

func cleanup(text : String) -> String:
	var cleanedText = ""
	var text2 = text.split("_")
	for i in text2:
		cleanedText = cleanedText + " " + i.capitalize()
		cleanedText.strip_edges()
	return cleanedText +units[text] +  ":"
