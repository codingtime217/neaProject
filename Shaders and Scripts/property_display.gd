extends Control

#collection of properties predefine
var parent : Node
var label : String
var value
var mat : String
var mode = "static"
var texture : Texture2D
#nodes inside the scene that will be interacted with
@onready var labelBox = $propertyLabel
@onready var valueBox = $propertyData
@onready var textureBox = $TextureRect
#units dicitonary
const units :=  {"conductivity" : " (W/mK)", "specificHeatCap" : " (J/kgK)", "density" : " (kg/m^3)", "temperature" : "(K)","thermalCrossSection" : "(barns)","thermalNeutronFlux" : "/cm^2s","fastNeutronFlux" : "/cm^2s", "fissileDensity" : "m^-3"}

func _ready() -> void:
	if mode == "static": #if static then normal
		parent = get_node("../..")
		parent.connect("freeDisplays",queue_free) #link so it can be removed
		mat = parent.mat
		if units.get(label,null) == null:
			queue_free()#simplifies display creation by removing any with a property not in the units dictionary
			
		#set the text to display
		labelBox.text = cleanup(label) 
		valueBox.text = toExponentialNotation(str(value))
	else:
		#if the other kind then just label + texture
		labelBox.text = cleanup(label)
		valueBox.visible = false
		textureBox.visible = true
		textureBox.texture = texture


func toExponentialNotation(number : String) -> String: #converts a string number to exponential notation
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


func cleanup(text : String) -> String: #cleans up the units by adding spaces and capitalising
	var cleanedText = ""
	var text2 = text.split("_")
	for i in text2:
		cleanedText = cleanedText + " " + i.capitalize()
		cleanedText.strip_edges()
	if units.get(text) != null:
		return cleanedText + units[text] +  ":"
	else:
		return toExponentialNotation(cleanedText) #also expontiated it if its a number set
