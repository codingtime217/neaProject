extends Control

signal ValueChanged(property,newValue)

var parent : Node
var property := 0
var value
var mat : String
var labelBox
var valueBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	labelBox = get_node("container/property")
	valueBox = get_node("container/SpinBox")
	parent = get_node("...")
	mat = parent.mat
	pass # Replace with function body.


func changed(newValue : float):
	value = newValue
	ValueChanged.emit(property,newValue)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#needs to both display current values and if changed overwrite them
	pass
