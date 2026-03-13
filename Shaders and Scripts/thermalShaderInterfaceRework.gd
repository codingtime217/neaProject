extends Node2D
@export_file var shaderPath : String

var rdManager = load("res://Shaders and Scripts/shaderManager.gd").new()
@export var workGroups := Vector3i(1,1,1)
var rd : RenderingDevice
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


func matDictToBytes(dict : Dictionary):
	var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd")
	var materialDict = jsonLoader.loadingJsonFile("res://materials/materialsProperties.json")
	var arrayForm := PackedByteArray([])
	arrayForm.resize(1024)
	for i in dict.keys():
		if dict.get(i,null) != null:
			var mat = dict[i]
			var properties = materialDict[mat]
			arrayForm.encode_double(i*32,properties["specificHeat"])
			arrayForm.encode_double(i*32+8,properties["conductivity"])
			arrayForm.encode_double(i*32+16,properties["density"]/1000)
			#the missing i*32+24 is blank data cuase its useless for stupid reasons
	return arrayForm


func dataSetup(initalData) -> void: #both shaders have this as the intial data setup function
	width = initalData[0][0]["width"]
	inputBytes = makeBufferArray(initalData[1])
	outputBytes = inputBytes
	
	
	var matDict = initalData[0][1]
	matDictBytes = matDictToBytes(matDict)
	
	workGroups = Vector3(width,height,1)
	
	
	constantInts = [10,width,1] #converting constants to a byte array
	constBytes.resize(16)
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])

func shaderSetup() -> void:
	

	rd = RenderingServer.create_local_rendering_device() #create rendering device, local so we choose when to call it
	var shaderSpirv = rdManager.importShaderFromFile(shaderPath)
	shaderRID = rd.shader_create_from_spirv(shaderSpirv) #setup the shader RID
	pipeline = rd.compute_pipeline_create(shaderRID) #create the pipeline
	
	
	#setting up uniforms and buffers
	constRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,constBytes.size(),constBytes)
	inBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,inputBytes.size(),inputBytes)
	outBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,outputBytes.size(),outputBytes)
	matRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,matDictBytes.size(),matDictBytes)
	
	
	inUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0,inBufferRID)
	constUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,1,constRID)
	matUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,2,matRID)
	outUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,3,outBufferRID)
	
	uniformSet = rd.uniform_set_create([inUniform,constUniform,matUniform,outUniform],shaderRID,0) #creates the set	
	
func get_output(rendering : RenderingDevice, buffer : RID) -> PackedByteArray:
	var outputAsBytes := rendering.buffer_get_data(buffer)
	return outputAsBytes
	


func makeBufferArray(data:Array) -> PackedByteArray:
	var newData := PackedByteArray()
	newData.resize(len(data) * 16)
	@warning_ignore("integer_division")
	height = len(data)/ width
	for i in range(0,len(data)):
		newData.encode_u32(i*16,data[i][0])
		newData.encode_double(i*16 + 8,data[i][1].get("thermalEnergy",0))
	return newData
	
	
func makeItBackIntoTheArray(data : PackedByteArray) -> Array:
	var returnArray = []
	
	@warning_ignore("integer_division")
	for i in range(0,len(data)/16):
		var matIndex = data.decode_u32(i*16)
		var thermalEnergy = data.decode_double(i*16 + 8)
		returnArray.append([matIndex,{"thermalEnergy" : thermalEnergy}])
	return returnArray

	
func outputGrid(buffer : PackedByteArray) -> void:
	@warning_ignore("integer_division")
	for i in range(0,len(buffer)/(16*width)):
		var toPrint = []
		toPrint.append("Row: " + str(i))
		for j in range(0,width):
			toPrint.append(str(buffer.decode_u32(i*width*16 + j*16)) + ", temp:" + str(buffer.decode_double(i*width*16 + j*16 + 8 )))
		print(toPrint)
	
func _ready() -> void:
	var buttonGroup = load("res://UI Themes and Schemes/speedControlsGroup.tres")
	buttonGroup.pressed.connect(changeTimeScale)
	
func freeRIDS() -> void:
	#assert(rd.uniform_set_is_valid(uniformSet))
	rd.free_rid(inBufferRID)
	rd.free_rid(outBufferRID)
	rd.free_rid(constRID)
	rd.free_rid(shaderRID)
	#assert(rd.uniform_set_is_valid(uniformSet))


func _runShader() -> void:
	rdManager.runShader(rd,pipeline,{0 : uniformSet},workGroups)
	rd.submit()
	rd.sync()
	var outputValues = get_output(rd,outBufferRID)
	rd.buffer_update(inBufferRID,0,outputValues.size(),outputValues)

# Called every frame. 'delta' is the elapsed time since the previous frame.
		
		
func returnOutput() -> Array:
	return makeItBackIntoTheArray(get_output(rd,outBufferRID))

func updateInput(newInputData) -> void:
	inputBytes = makeBufferArray(newInputData) #this does not work, the two datas are not the same
	rd.buffer_update(inBufferRID,0,inputBytes.size(),inputBytes)
	
func changeTimeScale(button : Button) -> void:
	timestep = (button.get_index()-1) * 60
	constantInts = [10,width,1]
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	rd.buffer_update(constRID,0,constBytes.size(),constBytes)
