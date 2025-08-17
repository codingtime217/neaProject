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
			grid[Vector2(i,j)] = {"colour" = Color(0,i/width,0),"vector" = Vector2(16,16), "value" = i*10,"conductivity"	= 1.0,}

func _draw() -> void:
	
	var offset = get_viewport_rect().size/2
	#draws all the tiles, offsetting such that the centre tile is the in middle of the screen
	for coord in grid.keys():
		var screen_pos : Vector2 = (coord-Vector2(width/2,height/2)) * dimensions + offset
		var screen_size := Vector2(32,32)
		draw_rect(Rect2(screen_pos, screen_size), grid[coord]["colour"])
		draw_line((screen_pos+Vector2(16,16)),(screen_pos+Vector2(16,16))+grid[coord]["vector"]/2,Color(1,1,1))
func _ready() -> void:
	_generate_grid()
	
	pass # Replace with function body.

func _getneighbours(position = Vector2()):
	
	var value
	const fetchVectors = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	var neighbours = []
	#fetches the 4 tiles around the position given, in anticlockwise order from the left hand side
	for i in fetchVectors:
		value = grid.get(position+i,null)
		if value != null:
			neighbours.append(value)
		else:
			neighbours.append({"conductivity" = 0.0})
	return neighbours

func _getflux(tile1,tile2):
	#finding heat flux using equation q = -kdeltaT, finding flux from 1 to 2
	#q is flux, k is conductivty, detlaT is differecne in temp/distance	
	var distance = 0.1 #o.1 m
	if tile1["conductivity"] == tile2["conductivity"]:
		#smae material, this simplifies things
		var dT = (tile2["value"] - tile1["value"])/distance
		return dT*-tile1["conductivity"]
	else:
		return 0 #i aint working this out yer

func _overallFlux(pos1= Vector2()):
	var neighbours = _getneighbours()
	var fluxes = []
	for i in neighbours:
		fluxes.append(_getflux(grid[pos1],i))
	var net = Vector2()
	net.x = fluxes[0] - fluxes[1]
	net.y = fluxes[2] - fluxes[3]
	print(net)
	grid[pos1]["vector"] = net/10

func _update():
	for i in width:
		for j in height:
			_overallFlux(Vector2(i,j))
	queue_redraw()
			#iterates through whole grid
			



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update()
	pass
