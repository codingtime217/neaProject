extends FoldableContainer

@onready var listOfModes = $Control/VBoxContainer/ItemList
@onready var key = $"../ColourKeys"
signal colourMode(colourModes:Dictionary)
var gradient
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gradient = Gradient.new() #create the gradient 
	gradient.offsets = PackedFloat32Array([0,0.5,1.0]) #set the colours and their positions
	gradient.colors = PackedColorArray([Color(0.316, 0.451, 0.952, 1.0),Color("46b67aff"),Color(0.99, 0.169, 0.546, 1.0)])
	pass # Replace with function body.

func changeColourMode(indexOfMode : int): #this func is linked to a different item being selected on the list of modes
	var newMode = listOfModes.get_item_text(indexOfMode).to_lower()
	var toEmit = {} #makes a dictionary with the data as this will be given to the tiles when they change draw mode
	toEmit["mode"] = newMode
	if newMode == "material":
		pass
	elif newMode == "temperature": #adds the data needed for drawing the gradient  to the dictionary
		var sim = get_node(^"/root/mainNode/Sim")
		var tempR = sim.tempRange
		toEmit["gradient"] = gradient
		toEmit["max"] = tempR.max_value
		toEmit["min"] = tempR.min_value
	elif newMode == "thermal energy":
		var sim = get_node(^"/root/mainNode/Sim")
		var tempR = sim.tempRange
		toEmit["min"] = 0
		toEmit["max"] = tempR.max_value * 2000
		toEmit["gradient"] = gradient
	colourMode.emit(toEmit)
