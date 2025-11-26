extends Node2D

var rdManager = load("res://shaderManager.gd").new()

var rd : RenderingDevice
var shaderFile : Resource
var shaderSpirv : RDShaderSPIRV
var shaderRID : RID

var input := PackedFloat32Array([1,[[1,1,1,1],[1,1,1,1],[1,1,1,1]],
				[[1,1,1,1],[10,1,1,1],[1,1,1,1]],
				[[1,1,1,1],[1,1,1,1],[1,1,1,1]]])
var inputBytes := input.to_byte_array()
var output := PackedFloat32Array([[[1,1,1,1],[1,1,1,1],[1,1,1,1]],
				[[1,1,1,1],[1,1,1,1],[1,1,1,1]],
				[[1,1,1,1],[1,1,1,1],[1,1,1,1]]])
var outputBytes := output.to_byte_array()
var inBufferRID : RID
var outBufferRID : RID
var inUniform : RDUniform
var outUniform : RDUniform
var uniformSet : RID
var pipeline : RID
var run = false
# Called when the node enters the scene tree for the first time.

func shaderSetup() -> void:
	rd = RenderingServer.create_local_rendering_device() #create rendering device, local so we choose when to call it
	shaderFile = load("res://thermal.glsl")
	shaderSpirv = rdManager.importShaderFromFile("res://thermal.glsl")
	shaderRID = rd.shader_create_from_spirv(shaderSpirv) #setup the shader RID
	pipeline = rd.compute_pipeline_create(shaderRID) #create the pipeline
	
	
	#setting up uniforms and buffers
	inBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,inputBytes.size(),inputBytes)
	outBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,outputBytes.size(),outputBytes)
	inUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0,inBufferRID)
	outUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,1,outBufferRID)
	uniformSet = rd.uniform_set_create([inUniform,outUniform],shaderRID,0) #creates the set
	
	rdManager.runShader(rd,pipeline,{0 : uniformSet},Vector3i(3,1,1)) #finish shader setup
	
	
func _ready() -> void:
	shaderSetup()
	#uniformIn.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
#	uniformIn.binding = 0 # this needs to match the "binding" in our shader file
#	uniformIn.add_id(inBuffer)
#	uniformOut.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
#	uniformOut.binding = 1
#	uniformOut.add_id(outBuffer)
#	uniformSet = rd.uniform_set_create([uniformIn,uniformOut],shader,0)
#	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
#	rd.compute_list_bind_uniform_set(compute_list, uniformSet, 0)
#	rd.compute_list_dispatch(compute_list, 1, 3, 1)
#	rd.compute_list_end()
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_dellta: float) -> void:
	if not run:
		rd.submit()
		rd.sync()
		run = true
	pass
