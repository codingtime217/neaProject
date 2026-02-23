extends Node2D
var editor = preload("res://Scenes/editor.tscn")
var editorInstance
var sim = preload("res://Scenes/sim.tscn")
var simInstance
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	editorInstance = editor.instantiate()
	get_tree().root.call_deferred("add_child",editorInstance)
	editorInstance.loaded.connect(linkRunButton)
	# Replace with function body.

func linkRunButton(button) -> void:
	button.pressed.connect(swapToSim)


func swapToSim() -> void:
	print("swapping")
	var grid = editorInstance.get_node("gridManager")
	var data = grid.dataForm()
	simInstance = sim.instantiate()
	simInstance.get_node("thermal").initialData = data 
	get_tree().root.add_child(simInstance)
	
	
