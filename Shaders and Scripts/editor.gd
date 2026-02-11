extends Node2D
var UI = preload("res://Scenes/UIeditor.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(UI.instantiate())
	
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
