extends TileMapLayer

var mousePos : Vector2 #current mouse position, self explanatory
var currentMatAtlas : Vector2i # will be used to store the current material's atlas coords
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	mousePos = get_local_mouse_position()
	if Input.is_action_pressed("left_click"):
		var tilePos = local_to_map(mousePos)
		set_cell(tilePos,0,Vector2i(0,0))
	elif Input.is_action_pressed("right_click"):
		var tilePos = local_to_map(mousePos)
		set_cell(tilePos,-1)
	pass
	
