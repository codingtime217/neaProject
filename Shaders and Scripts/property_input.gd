extends Control

signal ValueChanged(property,newValue)

var parent : Node
var label : String
var value := 0.0
var mat : String
#nodes
@onready var labelBox =$propertyLabel
@onready var valueBox = $SpinBox
const units := {"temperature" : [" (K)",0,2147483647,1], "enrichment" : ["",0,100,0.5]}

func _ready() -> void:
	parent = get_node("../..")
	parent.connect("freeDisplays",queue_free)
	mat = parent.mat
	if units.get(label,null) == null:
		queue_free()#simplifies display creation by removing any with a property not in the units dictionary
		return
	#set the text to display
	labelBox.text = cleanup(label)
	valueBox.value = value
	valueBox.max_value = units[label][2] #set max and min values for variable and the step
	valueBox.min_value = units[label][1]
	valueBox.step = units[label][3]

func cleanup(text : String) -> String: #cleans up the strings
	var cleanedText = ""
	var text2 = text.split("_")
	for i in text2:
		cleanedText = cleanedText + " " + i.capitalize()
		cleanedText.strip_edges()
	return cleanedText + units[text][0] +  ":"

func changed(newValue : float): #used to forward a signal to change the value in the selected tile
	value = newValue
	ValueChanged.emit(label,newValue)
