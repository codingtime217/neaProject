extends Node2D
var rdManager = load("res://Shaders and Scripts/shaderManager.gd").new()
@export var workGroups := Vector3i(1,1,1)
var rd : RenderingDevice
var shaderFile : Resource
var shaderSpirv : RDShaderSPIRV
var shaderRID : RID

var initialData : Array
var timestep := 60

var input : PackedFloat64Array
var inputBytes : PackedByteArray

var width : int
var height : int
var constantInts : Array
var constBytes := PackedByteArray()

var output : PackedFloat64Array
var outputBytes : PackedByteArray

var matDictBytes : PackedByteArray

var constRID : RID
var matRID : RID
var inBufferRID : RID
var outBufferRID : RID

var inUniform : RDUniform
var matUniform : RDUniform
var constUniform : RDUniform
var outUniform : RDUniform

var uniformSet : RID
var pipeline : RID
var run = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
