extends Node2D
#note on sim, each cell is treated as a 0.001m^3 cube (0.1m by 0.1m by 0.1m)


@export var dimensions = Vector2(32,32) #dimensions of each cell
@export var height = 10.0 #rectangle of cell dimesnon
@export var width = 10.0
@export var grid = {}

# Called when the node enters the scene tree for the first time.

func _generate_grid() -> void:
	for i in width:
		for j in height:
			grid[Vector2(i,j)] = {"colour" = Color(0,i/width,j/height),"vector" = Vector2(16,16), "value" = i*10,"conductivity"	= 10.0}

func _draw() -> void:
	print("drawing")
	var offset = get_viewport_rect().size/2
	#draws all the tiles, offsetting such that the centre tile is the in middle of the screen
	for coord in grid.keys():
		var screen_pos : Vector2 = (coord-Vector2(width/2,height/2)) * dimensions + offset
		var screen_size := Vector2(32,32)
		draw_rect(Rect2(screen_pos, screen_size), grid[coord]["colour"])
		draw_line((screen_pos+Vector2(16,16))-grid[coord]["vector"]/2,(screen_pos+Vector2(16,16))+grid[coord]["vector"]/2,Color(1,1,1))
func _ready() -> void:
	_generate_grid()
	
	pass # Replace with function body.

func _getneighbours(position = Vector2()):
	func _getneighbour(position):
		var value = grid.get(position+Vector2(i,j),null)
			if value == null:
				return("")
			else:
				return value
	var neighbours = [] # 
	#fetches the 4 tiles around the position given, in anticlockwise order from the left hand side
	for i in range(-1,2):
		neighbours.append(_getneightbour(position + Vector2(i,0)))	
	for j in range(-1,2):
			neighbours.append(_getneightbour(position + Vector2(0,j)))	
	
	return neighbours

func _getflux(position1=Vector2(),position2 = Vector2()):
	#finding heat flux using equation q = -kdeltaT, finding flux from 1 to 2
	#q is flux, k is conductivty, detlaT is differecne in temp/distance	
	var distance = 0.1 #o.1 m
	var bit1 = grid[position1]
	var bit2 = grid[position2]
	if bit1["conductity"] == bit2["conductivity"]:
		#smae material, this simplifies things
		var dT = (bit2["value"] - bit1["value"])/distance
		return dT*-bit1["conductivity"]
	else:
		return 0 #i aint working this out yer

func _overallFlux(pos1= Vector2()):
	
	pass


func _update():
	for i in width:
		for j in height:
			#iterates through whole grid
			_getneighbours(Vector2(i,j))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update()
	pass
