extends Node2D
@export_file var shaderPath : String

var rdManager = load("res://shaderManager.gd").new()

var rd : RenderingDevice
var shaderFile : Resource
var shaderSpirv : RDShaderSPIRV
var shaderRID : RID
var input := PackedFloat64Array([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,10,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1])
var inputBytes := input.to_byte_array()
var constants := PackedInt32Array([10,1,3,3])
var constBytes := constants.to_byte_array()
var output := input.duplicate()
var outputBytes := output.to_byte_array()
var constRid : RID
var inBufferRID : RID
var outBufferRID : RID
var inUniform : RDUniform
var outUniform : RDUniform
var constUniform : RDUniform
var uniformSet : RID
var pipeline : RID
var run = false
# Called when the node enters the scene tree for the first time.

func shaderSetup() -> void:
	

	rd = RenderingServer.create_local_rendering_device() #create rendering device, local so we choose when to call it
	shaderFile = load(shaderPath)
	shaderSpirv = rdManager.importShaderFromFile(shaderPath)
	shaderRID = rd.shader_create_from_spirv(shaderSpirv) #setup the shader RID
	pipeline = rd.compute_pipeline_create(shaderRID) #create the pipeline
	
	
	#setting up uniforms and buffers
	constRid = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,constBytes.size(),constBytes)
	inBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,inputBytes.size(),inputBytes)
	outBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,outputBytes.size(),outputBytes)
	inUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0,inBufferRID)
	outUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,1,outBufferRID)
	constUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,2,constRid)
	uniformSet = rd.uniform_set_create([inUniform,outUniform,constUniform],shaderRID,0) #creates the set
	
	rdManager.runShader(rd,pipeline,{0 : uniformSet},Vector3i(3,3,1)) #finish shader setup
	
func get_output(rendering : RenderingDevice, buffer : RID) -> PackedByteArray:
	var outputAsBytes := rendering.buffer_get_data(buffer)
	return outputAsBytes
	

	
func _ready() -> void:
	shaderSetup()
	
func freeRIDS() -> void:
	rd.free_rid(inBufferRID)
	rd.free_rid(outBufferRID)
	rd.free_rid(shaderRID)
	rd.free_rid(constRid)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_dellta: float) -> void:
	if not run:
		rd.submit()
		rd.sync()
		var outputValues = get_output(rd,outBufferRID)
		var inValues = get_output(rd,inBufferRID)
		print("Input: ")
		var j = 0
		var toPrint := ""
		#print(inValues.to_float64_array())
		for i in inValues.to_float64_array():
			if j < 3:
				toPrint = toPrint + "," + str(i)
				j += 1
			else:
				j = 0
				print(toPrint,",",i)
				toPrint = ""
		print("Output: ")
		toPrint = ""

		#print(outputValues.to_float64_array())
		for i in outputValues.to_float64_array():
			if j < 3:
				toPrint = toPrint + "," + str(i)
				j += 1
			else:
				j = 0
				print(toPrint,",",i)
				toPrint = ""
		#print(outputValues.to_float64_array())
		run = true
		freeRIDS()
	
	pass
