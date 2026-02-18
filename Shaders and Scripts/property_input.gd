extends Control

signal ValueChanged(property,newValue)

var parent : Node
var label : String
var value := 0.0
var mat : String
var labelBox
var valueBox
const units := {"temperature" : " (K)"}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	labelBox = get_node("propertyLabel")
	valueBox = get_node("SpinBox")
	parent = get_node("../..")
	parent.connect("freeDisplays",queue_free)
	mat = parent.mat
	labelBox.text = cleanup(label)
	valueBox.value = value
	pass # Replace with function body.

func cleanup(text : String) -> String:
	var cleanedText = ""
	var text2 = text.split("_")
	for i in text2:
		cleanedText = cleanedText + " " + i.capitalize()
		cleanedText.strip_edges()
	return cleanedText +units[text] +  ":"



func changed(newValue : float):
	value = newValue
	ValueChanged.emit(label,newValue)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#needs to both display current values and if changed overwrite them
	pass
