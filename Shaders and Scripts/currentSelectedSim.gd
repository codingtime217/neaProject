extends FoldableContainer
#needs rewriting, maybe wait until after visualistion
#this will instantiate propertyInput scenes in order to allow the properties of the tile to be modified

signal freeDisplays
var buttonGroup = load("res://UI Themes and Schemes/editorTileGroup.tres")
var propertyInput = load("res://Scenes/propertyInput.tscn")
var propertyDisplay = load("res://Scenes/propertyDisplay.tscn")
@onready var simManager = get_node(^"/root/mainNode/Sim")
var selected : Node2D
var mat : String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buttonGroup.pressed.connect(changeSelected)
	simManager.updatedGrid.connect(refresh)
	pass # Replace with function body.
 
func changeSelected(button : BaseButton):
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
	for i in properties[0].keys():
		addDisplay(i,properties[0][i])
	for i in properties[1].keys():
		addDisplay(i,properties[1][i])
	
func addDisplay(property,value):
	var display
	display = propertyDisplay.instantiate()
	display.label = property
	display.value = value
	get_node("VBoxContainer").add_child(display)

	
func refresh() -> void:
	if selected != null:
		changeSelected(selected.get_child(0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
