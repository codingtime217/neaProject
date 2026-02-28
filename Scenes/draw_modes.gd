extends FoldableContainer

@onready var listOfModes = $Control/VBoxContainer/ItemList
@onready var key = $"../ColourKeys"
signal colourMode(colourModes:Dictionary)
var gradient
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func changeColourMode(indexOfMode : int):
	var newMode = listOfModes.get_item_text(indexOfMode).to_lower()
	var toEmit = {}
	gradient = Gradient.new()
	print(newMode)
	if newMode == "material":
		toEmit["material"] = 0
	elif newMode == "temperature":
		toEmit["temperature"] = 0
		var sim = get_node(^"/root/mainNode/Sim")
		var tempR = sim.tempRange
		gradient.remove_point(1)
		gradient.remove_point(0)
		gradient.add_point(0,Color(0.316, 0.451, 0.952, 1.0))
		
		if tempR.min_value != 0:
			gradient.add_point((tempR.min_value+tempR.max_value)/512,Color(0.799, 0.721, 0.0, 1.0))
		gradient.add_point(tempR.max_value/256,Color(0.99, 0.169, 0.546, 1.0))
		toEmit["gradient"] = gradient
		toEmit["max"] = tempR.max_value
		print(toEmit)
	colourMode.emit(toEmit)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
