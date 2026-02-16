extends Control


var parent : Node
var label : String
var value
var mat : String
var labelBox
var valueBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	labelBox = get_node("propertyLabel")
	valueBox = get_node("propertyData")
	parent = get_node("../..")
	parent.connect("freeDisplays",queue_free)
	mat = parent.mat
	labelBox.text = label
	valueBox.text = str(value)
	pass # Replace with function body.




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
