extends Control


var parent : Node
var label : String
var value
var mat : String
var mode = "static"
var texture : Texture2D
@onready var labelBox = $propertyLabel
@onready var valueBox = $propertyData
@onready var textureBox = $TextureRect

const units :=  {"conductivity" : " (W/mK)", "specificHeatCap" : " (J/kgK)", "density" : " (kg/m^3)", "temperature" : "(K)","thermalCrossSection" : "(barns)"}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if mode == "static":
		parent = get_node("../..")
		parent.connect("freeDisplays",queue_free)
		mat = parent.mat
		if units.get(label,null) == null:
			queue_free()#ths will allow some ineffeceint but easy stuff
		labelBox.text = cleanup(label)
		valueBox.text = str(value)
	else:
		labelBox.text = cleanup(label)
		valueBox.visible = false
		textureBox.visible = true
		textureBox.texture = texture
	pass # Replace with function body.


func toExponentialNotation(number : String):
	var whole = number.split(".")[0]
	var decimal
	if len(number.split(".")) > 1:
		decimal = number.split(".")
	if len(whole) >= 1:
		@warning_ignore("integer_division")
		whole = str(roundi(int(whole)*100)/100) + "10^" + str(len(whole) -1)
		return whole
	elif len(decimal) > 1:
		var noZeros = decimal.count("0",0,-1)
		decimal = str(int(decimal) / (10**(len(decimal)-noZeros))) + "10^-" + noZeros 
		return decimal
	else:
		return number


func cleanup(text : String) -> String:
	var cleanedText = ""
	var text2 = text.split("_")
	for i in text2:
		cleanedText = cleanedText + " " + i.capitalize()
		cleanedText.strip_edges()
	if units.get(text) != null:
		return cleanedText + units[text] +  ":"
	else:
		return toExponentialNotation(cleanedText)
