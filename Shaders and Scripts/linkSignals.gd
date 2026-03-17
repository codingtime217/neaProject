extends Control


func _ready() -> void:
	var tileMap := get_node(^"/root/mainNode/Editor/gridManager")
	if tileMap != null:
		tileMap._link_signals()
