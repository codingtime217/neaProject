extends ItemList


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tileMap := get_node(^"/root/Editor/tileManager")
	if tileMap != null:
		tileMap._link_signals()
	pass # Replace with function body.
