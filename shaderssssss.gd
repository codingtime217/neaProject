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
	
func get_output(rendering : RenderingDevice, buffer : RID) -> PackedByteArray:
	var outputAsBytes := rendering.buffer_get_data(buffer)
	return outputAsBytes
	

	
func _ready() -> void:
	shaderSetup()
	
func freeRIDS() -> void:
	rd.free_rid(inBufferRID)
	rd.free_rid(outBufferRID)
	rd.free_rid(shaderRID)
	rd.free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_dellta: float) -> void:
	if not run:
		rd.submit()
		rd.sync()
		var outputValues = get_output(rd,outBufferRID)
		var inValues = get_output(rd,inBufferRID)
		print(input)
		print("Input: ", inValues.to_float32_array())
		print(outputValues.to_float32_array())
		print(outputValues)
		run = true
		freeRIDS()
	
	pass
