extends FoldableContainer

#this will instantiate propertyInput scenes in order to allow the properties of the tile to be modified
var buttonGroup = load("res://UI Themes and Schemes/editorTileGroup.tres")
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
	label.text = mat
	var display = get_node("VBoxContainer/HBoxContainer/Colour")
	display.texture = selected.get_child(0).icon
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
