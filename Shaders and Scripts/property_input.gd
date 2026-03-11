extends Control

signal ValueChanged(property,newValue)

var parent : Node
var label : String
var value := 0.0
var mat : String
@onready var labelBox =$propertyLabel
@onready var valueBox = $SpinBox
const units := {"temperature" : [" (K)",0,2,147,483,647,1], "enrichment" : ["",0,100,0.5]}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	parent = get_node("../..")
	parent.connect("freeDisplays",queue_free)
	mat = parent.mat
	labelBox.text = cleanup(label)
	valueBox.value = value
	valueBox.max_value = units[label][2]
	valueBox.min_value = units[label][1]
	valueBox.step = units[label][3]
	pass # Replace with function body.

func cleanup(text : String) -> String:
	var cleanedText = ""
	var text2 = text.split("_")
	for i in text2:
		cleanedText = cleanedText + " " + i.capitalize()
		cleanedText.strip_edges()
	return cleanedText + units[text][0] +  ":"



func changed(newValue : float):
	value = newValue
	ValueChanged.emit(label,newValue)
