extends Node2D

var rd := RenderingServer.create_local_rendering_device()
var shaderFile := load("res://thermal.glsl")
var shaderSpirv : RDShaderSPIRV = shaderFile.get_spirv()
var shader := rd.shader_create_from_spirv(shaderSpirv)

var input := PackedFloat32Array([1,[[1,1,1,1],[1,1,1,1],[1,1,1,1]],
				[[1,1,1,1],[10,1,1,1],[1,1,1,1]],
				[[1,1,1,1],[1,1,1,1],[1,1,1,1]]])
var inputBytes := input.to_byte_array()
var output := PackedFloat32Array([[[1,1,1,1],[1,1,1,1],[1,1,1,1]],

				[[1,1,1,1],[10,1,1,1],[1,1,1,1]],
				[[1,1,1,1],[1,1,1,1],[1,1,1,1]]])
var outputBytes := output.to_byte_array()
var inBuffer := rd.uniform_buffer_create(inputBytes.size(),inputBytes)
var outBuffer := rd.storage_buffer_create(outputBytes.size(),outputBytes)

var uniformIn := RDUniform.new()
var uniformInSet
var pipeline := rd.compute_pipeline_create(shader)
var compute_list := rd.compute_list_begin()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	uniformIn.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniformIn.binding = 0 # this needs to match the "binding" in our shader file
	uniformIn.add_id(inBuffer)
	uniformInSet = rd.uniform_set_create([uniformIn], shader, 0)
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniformInSet, 0)
	rd.compute_list_dispatch(compute_list, 5, 1, 1)
	rd.compute_list_end()
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_lta: float) -> void:
	pass
