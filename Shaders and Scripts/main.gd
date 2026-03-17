extends Node2D
var editor = preload("res://Scenes/editor.tscn") #load the editor packed scene
var editorInstance : Node
var sim = preload("res://Scenes/sim.tscn") #load the sim packed scene
var simInstance : Node

func _ready() -> void: #called on start
	editorInstance = editor.instantiate() #instantiate the two other scenes
	simInstance = sim.instantiate()
	call_deferred("add_child",editorInstance) #get the editor running
	editorInstance.loaded.connect(linkRunButton) #link the signals for scene transistions
	simInstance.loaded.connect(linkExitButton)
	
	
func linkRunButton(button) -> void: #these functions will be called when the sim/editor finishes loading to insure the connections are made
	button.pressed.connect(swapToSim)

func linkExitButton(button) -> void:
	button.pressed.connect(swapToEditor)

func swapToSim() -> void:
	if simInstance == null: #make sure we have the sim instantiated
		simInstance = sim.instantiate()
	
	var grid = editorInstance.get_node("gridManager") 
	var data = grid.dataForm() #get the data from the editor
	simInstance.simData = data
	simInstance.simDataSetup() #allow the sim to do its setup with the data
	simInstance.tileDimensions = grid.tileDimensions
	add_child(simInstance) #add the sim to the tree so it begins processin
	remove_child(editorInstance) #removing the editor as we are no longer using it
	
func swapToEditor() -> void:
	add_child(editorInstance) #return the editor to the tree
	simInstance.queue_free() #delete the sim so there won't be any accidental left overs
