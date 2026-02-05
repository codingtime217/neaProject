extends TileMapLayer

var mousePos : Vector2 #current mouse position, self explanatory
var currentMatAtlas : Vector3i # will be used to store the current material's atlas + coords 
# x is the atlas no, y and z are the atlas coords

func _ready() -> void:
	#call_deferred("_link_signals")
	pass # Replace with function body.

func _link_signals():
	var UINode = get_node(^"/root/UIEditor/cont/ItemList")
	UINode.item_selected.connect(selected)
	pass

func selected(index : int):
	currentMatAtlas.x = index
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	mousePos = get_local_mouse_position()
	if Input.is_action_pressed("left_click"):
		var tilePos = local_to_map(mousePos)
		set_cell(tilePos,currentMatAtlas.x,Vector2i(currentMatAtlas.y,currentMatAtlas.z))
	elif Input.is_action_pressed("right_click"):
		var tilePos = local_to_map(mousePos)
		set_cell(tilePos,-1)
	pass

#func _notification(what: int) -> void:
