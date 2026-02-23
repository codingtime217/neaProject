extends Node2D
var UI = preload("res://Scenes/UIeditor.tscn")
var UIinstance
signal loaded(runButton)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UIinstance = UI.instantiate()
	add_child(UIinstance)
	loaded.emit(UIinstance.get_node("CanvasLayer/PanelContainer/VBoxContainer/run"))
	pass # Replace with function body.
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
