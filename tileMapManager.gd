extends TileMapLayer

var mousePos : Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	mousePos = get_local_mouse_position()
	if Input.is_action_pressed("left_click"):
		var tilePos = local_to_map(mousePos)
		set_cell(tilePos,0,Vector2i(0,0))
	elif Input.is_action_pressed("right_click"):
		var tilePos = local_to_map(mousePos)
		set_cell(tilePos,-1)
	pass
	
