extends Node
#tis will be a combo of the other methods, ie instnacing nodes + dict/array for storing
#but use tilemap stuff to lock position to increments

@export var tileDimensions = Vector2i(16,16)



func _global_to_local(global : Vector2) -> Vector2:
	var local = Vector2i(global/tileDimensions)
	return local

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
