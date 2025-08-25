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
			grid[Vector2(i,j)] = {"colour" = Color(0,i/width,0),"vector" = Vector2(0,0), "value" = 10*i,"conductivity"	= 1,"specificCapacity" = 100.0}
func _draw() -> void:
	
	var offset = get_viewport_rect().size/2
	#draws all the tiles, offsetting such that the centre tile is the in middle of the screen
	for coord in grid.keys():
		var screen_pos : Vector2 = (coord-Vector2(width/2,height/2)) * dimensions + offset
		var screen_size := Vector2(32,32)
		draw_rect(Rect2(screen_pos, screen_size), grid[coord]["colour"])
		draw_line((screen_pos+Vector2(16,16)),(screen_pos+Vector2(16,16))+grid[coord]["vector"],Color(1,1,1))
func _ready() -> void:
	_generate_grid()
	
	pass # Replace with function body.

func _getneighbours(location = Vector2()):
	var value
	const fetchVectors = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	var neighbours = []
	var toFetch = Vector2(0,0)
	#fetches the 4 tiles around the position given, in anticlockwise order from the left hand side
	for i in fetchVectors:
		toFetch = location + i
		value = grid.get(toFetch,null)
		if value != null:
			neighbours.append(value)
		else:
			neighbours.append({"conductivity" = 0.0})
	return neighbours

func _getHeatFlux(tile1,tile2):
	#finding heat flux using equation q = -kdeltaT, finding flux from 1 to 2
	#q is flux, k is conductivty, detlaT is differecne in temp/distance	
	var distance = 0.1 #o.1 m
	if tile1["conductivity"] == tile2["conductivity"]:
		#smae material, this simplifies things
		#print("not coid")
		var dT = (tile1["value"] - tile2["value"])/distance # should find flux into tile1 (positive is tile1 going up)
		return dT*-tile1["conductivity"]
	else:
		#print("void tile")
		return 0.0 #i aint working this out yer

func _overallFlux(pos1= Vector2()): #define flux from left to right as positive and right to left as negative
	#flux down is pos, flux up is negative
	#thus aligns with screen coords
	var neighbours = _getneighbours(pos1)
	var fluxes = []
	var net  = 0.0
	var flux = 0.0
	for i in neighbours: #finds all the individual fluxes
		flux =_getHeatFlux(grid[pos1],i) 
		fluxes.append(flux) #stores in an array for vector drawing
		net += flux #sums them for the overall cahnge
	var vFlux = Vector2()
	vFlux.x = fluxes[1] - fluxes[0]
	vFlux.y = fluxes[2] - fluxes[3] #makes the vector by resolving opposite sides
	return [net,vFlux]


func _update():
	var netFlux
	var fluxes
	var newGrid = grid.duplicate(true) #make a copy to overwrite everything at once
	for currentCell in grid.keys():
		#_overallFlux(Vector2(i,j))
		#fluxIn =_summedFlux(currentCell)
		fluxes =  _overallFlux(currentCell) 
		netFlux= fluxes[0]#get the overall change
		
		newGrid[currentCell]["value"] += netFlux/newGrid[currentCell]["specificCapacity"] #change the temp
		newGrid[currentCell]["vector"] = fluxes[1] #update vector
		newGrid[currentCell]["colour"] = Color(0,newGrid[currentCell]["value"]/180,0) #update colour, need better func to have a wider range of colour than black to green
	grid = newGrid #overwrite grid
	queue_redraw() #redraw




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update()
	pass
