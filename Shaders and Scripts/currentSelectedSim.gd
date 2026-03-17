extends FoldableContainer

signal freeDisplays
var buttonGroup = load("res://UI Themes and Schemes/editorTileGroup.tres")
var propertyInput = load("res://Scenes/propertyInput.tscn")
var propertyDisplay = load("res://Scenes/propertyDisplay.tscn")
@onready var simManager = get_node(^"/root/mainNode/Sim")
var selected : Node2D
var mat : String

func _ready() -> void: # links to the signals for changing selected or updating the displays
	buttonGroup.pressed.connect(changeSelected)
	simManager.updatedGrid.connect(refresh)
 
func changeSelected(button : BaseButton): #mostly the same as in the editor equivalent
	freeDisplays.emit()
	selected = button.get_parent()
	mat = selected.compound
	var label = get_node("VBoxContainer/HBoxContainer/TileName")
	label.text = mat.capitalize()
	var display = get_node("VBoxContainer/HBoxContainer/Colour")
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([selected.colour])
	display.texture =GradientTexture1D.new()
	display.texture.gradient = gradient
	display.texture.width = 16
	display.size = Vector2(16,16)
	var properties = selected.get_variable_list()
	for i in properties[0].keys(): #unlike in the editor, all values are displays, no inputs
		if i != "fissile" and i != "control": #skip them as they aren't continous variables
			addDisplay(i,properties[0][i])
	for i in properties[1].keys():
		addDisplay(i,properties[1][i])
	
func addDisplay(property,value): #see editor currently selected
	var display
	display = propertyDisplay.instantiate()
	display.label = property
	display.value = round(value*100)/100
	get_node("VBoxContainer").add_child(display)

	
func refresh(_data) -> void: #redoes all the displays to account for data changing
	if selected != null:
		changeSelected(selected.get_child(0))
