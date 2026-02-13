extends FoldableContainer

#this will instantiate propertyInput scenes in order to allow the properties of the tile to be modified
var buttonGroup = load("res://UI Themes and Schemes/editorTileGroup.tres")
var propertyInput = load("res://Scenes/propertyInput.tscn")
var propertyDisplay = load("res://Scenes/propertyDisplay.tscn")

var selected : Node2D
var mat : String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buttonGroup.pressed.connect(changeSelected)
	pass # Replace with function body.
 
func changeSelected(button : BaseButton):
	selected = button.get_parent()
	mat = selected.compound
	var label = get_node("VBoxContainer/HBoxContainer/TileName")
	label.text = mat.capitalize()
	var display = get_node("VBoxContainer/HBoxContainer/Colour")
	display.texture = selected.get_child(0).icon
	
func addDisplay(property,value,constant := false):
	var display
	if constant:
		display = propertyDisplay.instantiate()
		display.property = property
	else:
		display = propertyInput.instantiate()
		display.property = property
	get_node("VBoxContainer/HBoxContainer").add_child(display)
	

func updateProperty():
	pass
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
