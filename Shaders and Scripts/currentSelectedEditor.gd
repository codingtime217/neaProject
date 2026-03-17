extends FoldableContainer

signal freeDisplays
var buttonGroup = load("res://UI Themes and Schemes/editorTileGroup.tres") #the button group all tiles are part of
var propertyInput = load("res://Scenes/propertyInput.tscn") #packed scenes used for diplays/inputs
var propertyDisplay = load("res://Scenes/propertyDisplay.tscn")
var displaysActive := false #keep track of if we have displays on or not
var selected : Node2D
var mat : String


func _ready() -> void:
	buttonGroup.pressed.connect(changeSelected) #connect the buttongroup to the method
 
func changeSelected(button : BaseButton): #called when a tile is selected, the argument button is the button pressed
	displaysActive = false
	freeDisplays.emit() #get rid of existing displays
	selected = button.get_parent() #get the tile node of the selected tile
	mat = selected.compound
	#make the little title of the tile selected
	var label = get_node("VBoxContainer/HBoxContainer/TileName")
	label.text = mat.capitalize()
	var display = get_node("VBoxContainer/HBoxContainer/Colour")
	display.texture = selected.get_child(0).texture_normal
	
	#iterate through the tiles properties and initialise displays for each
	var properties = selected.get_variable_list()
	for i in properties[0].keys():
		addDisplay(i,properties[0][i],true)
	for i in properties[1].keys():
		#for variables initalise an input display so they can changed
		addDisplay(i,properties[1][i])
	
func addDisplay(property,value,constant := false):
	var display
	if constant: #the property is constant so just make a display
		display = propertyDisplay.instantiate()
		display.label = property
		display.value = roundf(value)
	else: #the property is varaible so initialise an input
		display = propertyInput.instantiate()
		display.label = property
		display.value = value
		display.ValueChanged.connect(updateProperty) #connect its updating to her
	get_node("VBoxContainer").add_child(display) #add it to the tree in the right spot
	displaysActive = true #we now have displays active

func updateProperty(property, newValue): #serves to forward update property signals to the selected tile
	if displaysActive:
		selected._update_properties({property : newValue})
