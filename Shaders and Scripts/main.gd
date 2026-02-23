extends Node2D
var editor = preload("res://Scenes/editor.tscn")
var editorInstance : Node
var sim = preload("res://Scenes/sim.tscn")
var simInstance : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	editorInstance = editor.instantiate()
	simInstance = sim.instantiate()
	#get_tree().root.call_deferred("add_child",editorInstance)
	call_deferred("add_child",editorInstance)
	editorInstance.loaded.connect(linkRunButton)
	simInstance.loaded.connect(linkExitButton)
	# Replace with function body.

func linkRunButton(button) -> void:
	button.pressed.connect(swapToSim)

func linkExitButton(button) -> void:
	button.pressed.connect(swapToEditor)

func swapToSim() -> void:
	if simInstance == null:
		simInstance = sim.instantiate()
	var grid = editorInstance.get_node("gridManager")
	var data = grid.dataForm()
	
	simInstance.get_node("thermal").initialData = data 
	add_child(simInstance)
	remove_child(editorInstance)
	
func swapToEditor() -> void:
	add_child(editorInstance)
	simInstance.queue_free()
	
	
