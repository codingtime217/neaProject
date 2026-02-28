extends FoldableContainer


@onready var gradientText = $Formatter/GradientKeys/Gradeint
@onready var minLabel = $Formatter/GradientKeys/Min
@onready var maxLabel = $Formatter/GradientKeys/Max
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func colourModeChanged(colourModes: Dictionary) -> void:
	if colourModes.get("gradient") != null:
		var gradient = colourModes["gradient"]
		gradientText.texture = GradientTexture1D.new()
		gradientText.texture.gradient = gradient
		minLabel.text = "0K"
		maxLabel.text = str(colourModes["max"]) + "K"
