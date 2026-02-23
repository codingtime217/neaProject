extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tileMap := get_node(^"/root/mainNode/Editor/gridManager")
	if tileMap != null:
		tileMap._link_signals()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
