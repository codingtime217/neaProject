extends Node2D
#note on sim, each cell is treated as a 0.001m^3 cube (0.1m by 0.1m by 0.1m)


@export var dimensions = Vector2(32,32) #dimensions of each cell
@export var height = 10.0 #rectangle of cell dimesnon
@export var width = 10.0
@export var grid = {}
var tile = load("res://tile.gd")

# Called when the node enters the scene tree for the first time.

			
func _generateGrid() -> void:
	var offset = get_viewport_rect().size/2 - Vector2(width*16, height *16)
	var newcoord  #stores the key for each tile about to be made
	var newtile #stores the tile breifly
	for i in width:
		for j in height:
			newcoord = Vector2(i,j) #sets the key/coordinates
			newtile = tile.new()
			newtile.setup("water",newcoord*16)
			add_child(newtile)
			grid[newcoord] = newtile
			 # instantiates a new water tile, and gives it its global position (the key * 32 as 32 by 32 sqaures)
	
#func _draw() -> void:
	#
	#var offset = get_viewport_rect().size/2
	##draws all the tiles, offsetting such that the centre tile is the in middle of the screen
	#for coord in grid.keys():
		#var screen_pos : Vector2 = (coord-Vector2(width/2,height/2)) * dimensions + offset
		#var screen_size := Vector2(32,32)
		#draw_rect(Rect2(screen_pos, screen_size), grid[coord]["colour"])
		#draw_line((screen_pos+Vector2(16,16)),(screen_pos+Vector2(16,16))+grid[coord]["vector"],Color(1,1,1))
func _ready() -> void:
	_generateGrid()
	
	pass # Replace with function body.


func _getNeighbours(location = Vector2()):
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
			neighbours.append(null)
	return neighbours
	
	
	


func _getHeatFlux(tile1,tile2):
	#finding heat flux using equation q = -kdeltaT, finding flux from 1 to 2
	#q is flux, k is conductivty, detlaT is differecne in temp/distance	
	if (tile1 == null) or (tile2 == null) or tile1.compound == "void" or tile2.compound == "void":
		return 0
	var distance = 0.1 #o.1 m
	if tile1.conductivity == tile2.conductivity:
		#smae material, this simplifies things
		#print("not coid")
		var dT = (tile1.temp - tile2.temp)/distance # should find flux into tile1 (positive is tile1 going up)
		return dT*-tile1.conductivity
	else:
		#print("void tile")
		return 0.0 #i aint working this out yer

func _overallFlux(pos1= Vector2()): #define flux from left to right as positive and right to left as negative
	#flux down is pos, flux up is negative
	#thus aligns with screen coords
	var neighbours = _getNeighbours(pos1)
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
	
	for currentCell in grid.keys():
		#_overallFlux(Vector2(i,j))
		#fluxIn =_summedFlux(currentCell)
		fluxes =  _overallFlux(currentCell) 
		netFlux= fluxes[0]#get the overall change
		
		grid[currentCell].temp += netFlux/grid[currentCell].specificHeatCap #change the temp
		grid[currentCell].vector = fluxes[1] #update vector


	#queue_redraw() #redraw




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update()
	pass
