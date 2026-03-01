extends FoldableContainer

const units = {"conductivity" : " (W/mK)", "specificHeatCap" : " (J/kgK)", "density" : " (kg/m^3)", "temperature" : "K", "thermal energy" : "J"}
@onready var gradientText = $Formatter/GradientKeys/Gradeint
@onready var minLabel = $Formatter/GradientKeys/Min
@onready var maxLabel = $Formatter/GradientKeys/Max
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func colourModeChanged(colourModes: Dictionary) -> void:
	if colourModes.get("gradient") != null:
		$Formatter/GradientKeys.visible = true
		$Formatter/GridKeys.visible = false
		var gradient = colourModes["gradient"]
		gradientText.texture = GradientTexture1D.new()
		gradientText.texture.gradient = gradient
		minLabel.text =  toExponentialNotation(str(colourModes["min"])) + " " + units[colourModes["mode"]]
		maxLabel.text = toExponentialNotation(str(colourModes["max"])) + " " +  units[colourModes["mode"]]
	elif colourModes.get("material") != null:
		$Formatter/GradientKeys.visible = false
		$Formatter/GridKeys.visible = true



func toExponentialNotation(number : String):
	var whole = number.split(".")[0]
	var decimal
	if len(number.split(".")) > 1:
		decimal = number.split(".")
	if len(whole) >= 1:
		whole = str(roundf(int(whole)*100)/(10**(len(whole)+1))) + "*10^" + str(len(whole) -1)
		print(whole)
		return whole
	elif len(decimal) > 1:
		var noZeros = decimal.count("0",0,-1)
		decimal = str(int(decimal) / (10**(len(decimal)-noZeros))) + "10^-" + noZeros 
		return decimal
	else:
		return number
