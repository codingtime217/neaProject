extends Node2D

@export var dimensions = Vector2(32,32) #dimensions of each cell
@export var height = 10.0
@export var width = 10.0
var grid = {}

# Called when the node enters the scene tree for the first time.

func _generate_grid() -> void:
	for i in width:
		for j in height:
			grid[Vector2(i,j)] = {"colour" = Color(0,i/width,j/height)}

func _draw() -> void:
	print("drawing")
	var offset = get_viewport_rect().size/2
	for coord in grid.keys():
		var screen_pos : Vector2 = (coord-Vector2(width/2,height/2)) * dimensions + offset
		var screen_size := Vector2(32,32)
		draw_rect(Rect2(screen_pos, screen_size), grid[coord]["colour"])

func _ready() -> void:
	_generate_grid()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
