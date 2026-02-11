extends Control
var parent : Node
var property := 0
var mat : String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	property = get_index()
	mat = parent.material
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#needs to both display current values and if changed overwrite them
	pass
