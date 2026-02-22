extends Node2D
var editor = preload("res://Scenes/editor.tscn")
var editorInstance
var sim = preload("res://Scenes/sim.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	editorInstance = editor.instantiate()
	get_tree().root.call_deferred("add_child",editorInstance)
	editorInstance.loaded.connect(linkRunButton)
	pass # Replace with function body.

func linkRunButton(button) -> void:
	button.pressed.connect(swapToSim)


func swapToSim() -> void:
	print("swapping")
	pass
	
func runSim() -> void:
	#var gridManager = $gridManager
	#var data = gridManager.data_form()
	
	get_tree().change_scene_to_file("res://Scenes/editor.tscn")
	pass
