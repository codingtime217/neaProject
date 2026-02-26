extends Node2D
var UI = preload("res://Scenes/UISim.tscn")
var UIinstance
var dataGrid : Dictionary
var tileDimensions = Vector2(16,16)
var width : int
var matDict : Dictionary
@onready var thermShader = $thermal

signal loaded(runButton)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UIinstance = UI.instantiate()
	add_child(UIinstance)
	loaded.emit(UIinstance.get_node("CanvasLayer/SpeedOptions/HBoxContainer/Halt"))
	pass # Replace with function body.

func _local_to_global(local : Vector2i) -> Vector2: #converts coords on the grid to global coords
	@warning_ignore("integer_division")
	var global = Vector2i(local.x * 16,local.y * 16) + 1/2*tileDimensions
	return global

func _process(_delta: float) -> void: #call the two shaders in sequence then idk
	thermShader._runShader()
	var currentData = thermShader.returnOutput()
	thermShader.updateInput(currentData)
	var dictData = toDictForm(currentData)
	print(dictData)
	#updateGrid(currentData)
	
	
	
func updateGrid(data : Dictionary) -> void:
	pass


func toDictForm(data : PackedByteArray, _type = "therm") -> Dictionary:
	var currentCord = Vector2(0,0)
	var i = 0
	var newDict = {}
	@warning_ignore("integer_division")
	while i < len(data)/16:
		var materialIndex = data.decode_u32(i*16)
		var temperature = data.decode_double(i*16 + 8)
		newDict[currentCord] = {"mat" : materialIndex, "temperature" : temperature}
		i +=1
		if (i + 1) % width:
			currentCord.y += 1
			currentCord.x = 0
		else:
			currentCord.x += 1
	return newDict
