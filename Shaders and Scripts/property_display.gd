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

const units :=  {"conductivity" : " (W/mK)", "specificHeatCap" : " (J/kgK)", "density" : " (kg/m^3)", "temperature" : "(K)","thermalCrossSection" : "(barns)","thermalNeutronFlux" : "/cm^2s","fastNeutronFlux" : "/cm^2s", "fissileDensity" : "m^-3"}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if mode == "static":
		parent = get_node("../..")
		parent.connect("freeDisplays",queue_free)
		mat = parent.mat
		if units.get(label,null) == null:
			queue_free()#ths will allow some ineffeceint but easy stuff
		labelBox.text = cleanup(label)
		valueBox.text = toExponentialNotation(str(value))
	else:
		labelBox.text = cleanup(label)
		valueBox.visible = false
		textureBox.visible = true
		textureBox.texture = texture
	pass # Replace with function body.


func toExponentialNotation(number : String) -> String:
	var whole = number.split(".")[0]
	var decimal
	if len(number.split(".")) > 1:
		decimal = number.split(".")
	if len(whole) >= 3:
		@warning_ignore("integer_division")
		whole = whole[0]+whole[1]+whole[2] + "*10^" + str(len(whole)-3)
		return whole
	elif len(decimal) > 1:
		decimal = str(decimal)
		var noZeros = decimal.count("0",0,-1)
		decimal = str(int(decimal) / (10**(len(decimal)-noZeros))) + "10^-" + str(noZeros) 
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
