extends GridContainer

var display = load("res://Scenes/propertyDisplay.tscn")
var matDict : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	matDict = loadingJsonFile("res://materials/materialsProperties.json")
	for i in matDict.keys():
		if i == "void":
			continue
		var newDis = display.instantiate()
		newDis.mode = "grid"
		newDis.label = i
		newDis.texture = load("res://materials/" + i + ".tres")
		add_child(newDis)


func loadingJsonFile(path : String):
	var file = FileAccess.open(path,FileAccess.READ)
	var text = file.get_as_text()
	var json_result = JSON.parse_string(text)
	return json_result
