extends TileMapLayer

var mousePos : Vector2 #current mouse position, self explanatory
var currentMatAtlas : Vector3i # will be used to store the current material's atlas + coords 
# x is the atlas no, y and z are the atlas coords

func _ready() -> void:
	pass # Replace with function body.

func _link_signals():
	var UINode = get_node(^"/root/UIEditor/CanvasLayer/cont/ItemList")
	UINode.item_selected.connect(selected)
	var saveButton = get_node(^"/root/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/save")
	saveButton.pressed.connect(save)
	

func selected(index : int):
	print(index)
	currentMatAtlas.x = index
	
	
func save() -> void:
	#use some stuff to turn the tileMap into a big string array
	var fileNameNode = get_node(^"/root/UIEditor/CanvasLayer/PanelContainer/VBoxContainer/HBoxContainer/simName")
	var fileName = fileNameNode.text + ".txt"
	if fileName == "":
		fileName = "sim.txt"
	print(fileName)
	writeToFile(fileName,metaData())
	
	
func convertToData() -> String:
	var cellData : String
	var cell : TileData
	for i in get_used_cells():
		cell = get_cell_tile_data(i)
		cellData = cell.temperature
	return cellData
	
func metaData() -> String:
	var dimensions = str(get_used_rect().size) + "\n"
	
	return dimensions + "hello"
	
	
func writeToFile(fileName,content):
	var file = FileAccess.open(fileName,FileAccess.WRITE)
	file.store_string(content)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	mousePos = get_local_mouse_position()
	if Input.is_action_pressed("left_click"):
		var tilePos = local_to_map(mousePos)
		set_cell(tilePos,currentMatAtlas.x,Vector2i(currentMatAtlas.y,currentMatAtlas.z))
	elif Input.is_action_pressed("right_click"):
		var tilePos = local_to_map(mousePos)
		set_cell(tilePos,-1)

#func _notification(what: int) -> void:
