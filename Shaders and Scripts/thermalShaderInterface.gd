extends Node2D
@export_file var shaderPath : String

var rdManager = load("res://Shaders and Scripts/shaderManager.gd").new()

var rd : RenderingDevice
var shaderFile : Resource
var shaderSpirv : RDShaderSPIRV
var shaderRID : RID
var input : PackedFloat64Array
var inputBytes : PackedByteArray
var constants := PackedInt32Array([10,1,10,10])
var constBytes := constants.to_byte_array()
var output : PackedFloat64Array
var outputBytes : PackedByteArray
var constRid : RID
var inBufferRID : RID
var outBufferRID : RID
var inUniform : RDUniform
var outUniform : RDUniform
var constUniform : RDUniform
var uniformSet : RID
var pipeline : RID
var run = 0
# Called when the node enters the scene tree for the first time.

func shaderSetup() -> void:
	

	rd = RenderingServer.create_local_rendering_device() #create rendering device, local so we choose when to call it
	shaderFile = load(shaderPath)
	shaderSpirv = rdManager.importShaderFromFile(shaderPath)
	shaderRID = rd.shader_create_from_spirv(shaderSpirv) #setup the shader RID
	pipeline = rd.compute_pipeline_create(shaderRID) #create the pipeline
	
	#making input data
	inputBytes = makeBufferArray(get_node("gridManager").grid)
	outputBytes = inputBytes
	
	
	#setting up uniforms and buffers
	constRid = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,constBytes.size(),constBytes)
	inBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,inputBytes.size(),inputBytes)
	outBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,outputBytes.size(),outputBytes)
	inUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0,inBufferRID)
	outUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,1,outBufferRID)
	constUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,2,constRid)
	uniformSet = rd.uniform_set_create([inUniform,outUniform,constUniform],shaderRID,0) #creates the set
	
	rdManager.runShader(rd,pipeline,{0 : uniformSet},Vector3i(10,10,1)) #finish shader setup
	
	
func get_output(rendering : RenderingDevice, buffer : RID) -> PackedByteArray:
	var outputAsBytes := rendering.buffer_get_data(buffer)
	return outputAsBytes
	

func makeBufferArray(cells : Dictionary) -> PackedByteArray:
	var bufferArray : PackedFloat64Array
	var currentCell
	print(cells["height"])
	for i in range(0,cells["height"]): #goes through in order from top to bottom left to right
		for j in range(0,cells["width"]):
			currentCell = cells[Vector2(j,i)]
			bufferArray = bufferArray + PackedFloat64Array([currentCell.thermalE,currentCell.conductivity,currentCell.specificHeatCap,currentCell.mass])
	return bufferArray.to_byte_array()
	
func outputGrid(buffer : PackedByteArray,width : int) -> void:
	var bufferFloat = buffer.to_float64_array()
	for i in range(0,len(bufferFloat)/(4*width)):
		var toPrint = []
		toPrint.append("Row: " + str(i))
		for j in range(0,width):
			toPrint.append(int(bufferFloat[4*(i*width+j)]))
		print(toPrint)
	
func _ready() -> void:
	shaderSetup()
	
func freeRIDS() -> void:
	#assert(rd.uniform_set_is_valid(uniformSet))
	rd.free_rid(inBufferRID)
	rd.free_rid(outBufferRID)
	rd.free_rid(constRid)
	rd.free_rid(shaderRID)
	#assert(rd.uniform_set_is_valid(uniformSet))
	print("Freed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_dellta: float) -> void:
	if run < 2:
		rd.submit()
		rd.sync()
		var outputValues = get_output(rd,outBufferRID)
		var inValues = get_output(rd,inBufferRID)
		print("Input:")
		outputGrid(inValues,10)
		print("Output:")
		outputGrid(outputValues,10)
		run += 1
		rd.buffer_update(inBufferRID,0,outputValues.size(),outputValues)
		rdManager.runShader(rd,pipeline,{0 : uniformSet},Vector3i(10,2,1))
	elif run <= 2:
		freeRIDS()
		run +=1
	else:
		pass
