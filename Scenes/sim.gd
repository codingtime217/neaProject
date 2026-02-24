extends Node2D
var UI = preload("res://Scenes/UISim.tscn")
var UIinstance

signal loaded(runButton)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UIinstance = UI.instantiate()
	
	add_child(UIinstance)
	loaded.emit(UIinstance.get_node("CanvasLayer/SpeedOptions/HBoxContainer/Halt"))
	pass # Replace with function body.
