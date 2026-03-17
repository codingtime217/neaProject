extends Node2D
var UI = preload("res://Scenes/UIeditor.tscn") #get the UI scene as a packed scene
var UIinstance
signal loaded(runButton) #signal used to say it has finished loading and connect the run button to the main node


func _ready() -> void:
	UIinstance = UI.instantiate() #instantiate the UI
	add_child(UIinstance) #add the UI to the scene tree as a child of Editor
	loaded.emit(UIinstance.get_node("CanvasLayer/PanelContainer/VBoxContainer/run")) #emit the signal with the run button as the argument
