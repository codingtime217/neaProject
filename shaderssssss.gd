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

				[[1,1,1,1],[1,1,1,1],[1,1,1,1]],
				[[1,1,1,1],[1,1,1,1],[1,1,1,1]]])
var outputBytes := output.to_byte_array()
var inBuffer := rd.uniform_buffer_create(inputBytes.size(),inputBytes)
var outBuffer := rd.storage_buffer_create(outputBytes.size(),outputBytes)
var uniformIn := RDUniform.new()
var uniformOut := RDUniform.new()
var uniformSet : RID
var pipeline := rd.compute_pipeline_create(shader)
var compute_list := rd.compute_list_begin()
var run = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	uniformIn.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	uniformIn.binding = 0 # this needs to match the "binding" in our shader file
	uniformIn.add_id(inBuffer)
	uniformOut.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniformOut.binding = 1
	uniformOut.add_id(outBuffer)
	uniformSet = rd.uniform_set_create([uniformIn,uniformOut],shader,0)
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniformSet, 0)
	rd.compute_list_dispatch(compute_list, 1, 3, 1)
	rd.compute_list_end()
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_lta: float) -> void:
	if not run:
		rd.submit()
		rd.sync()
		run = true
	pass
