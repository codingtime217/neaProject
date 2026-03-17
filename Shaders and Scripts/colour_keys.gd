extends FoldableContainer
#units dictionary
const units = {"conductivity" : " (W/mK)", "specificHeatCap" : " (J/kgK)", "density" : " (kg/m^3)", "temperature" : "K", "thermal energy" : "J"}
#get the labels used to label the gradient key
@onready var gradientText = $Formatter/GradientKeys/Gradeint
@onready var minLabel = $Formatter/GradientKeys/Min
@onready var maxLabel = $Formatter/GradientKeys/Max

func colourModeChanged(colourModes: Dictionary) -> void: #when the colour mode changes it needs to update
	if colourModes.get("gradient") != null: #if its a gradient mode make gradient stuff visible and grid stuff invisble
		$Formatter/GradientKeys.visible = true
		$Formatter/GridKeys.visible = false
		var gradient = colourModes["gradient"]
		#make a new texture for the key
		gradientText.texture = GradientTexture1D.new()
		gradientText.texture.gradient = gradient #set it to the gradient
		minLabel.text =  toExponentialNotation(str(colourModes["min"])) + " " + units[colourModes["mode"]] #update the labels
		maxLabel.text = toExponentialNotation(str(colourModes["max"])) + " " +  units[colourModes["mode"]]
	elif colourModes.get("material") != null: #if its material then make gradient hidden and material visible
		$Formatter/GradientKeys.visible = false
		$Formatter/GridKeys.visible = true



func toExponentialNotation(number : String): #used to convert a number string into exponetial notation
	var whole = number.split(".")[0]
	var decimal
	if len(number.split(".")) > 1: #splits it into decimal and whole
		decimal = number.split(".")
	if len(whole) > 1: #if its >1 then display as whole number
		whole = str(roundf(int(whole)*100)/(10**(len(whole)+1))) + "*10^" + str(len(whole) -1)
		return whole
	if decimal != null and len(decimal) > 1: #otherwise decimal
		var noZeros = decimal.count("0",0,-1)
		decimal = str(int(decimal) / (10**(len(decimal)-noZeros))) + "10^-" + noZeros 
		return decimal
	else:
		return number #if it seems to be neither leave it alone
