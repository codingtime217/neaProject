extends Node2D
@export_file var shaderPath : String

var rdManager = load("res://Shaders and Scripts/shaderManager.gd").new()
@export var workGroups := Vector3i(2,2,1)
var rd : RenderingDevice
var shaderFile : Resource
var shaderSpirv : RDShaderSPIRV
var shaderRID : RID

var initialData : Array
var timestep := 7200

var input : PackedFloat64Array
var inputBytes : PackedByteArray

var width : int
var constantInts : Array
var constBytes := PackedByteArray()

var output : PackedFloat64Array
var outputBytes : PackedByteArray

var matDict : Dictionary
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

func shaderSetup() -> void:
	

	rd = RenderingServer.create_local_rendering_device() #create rendering device, local so we choose when to call it
	shaderFile = load(shaderPath)
	shaderSpirv = rdManager.importShaderFromFile(shaderPath)
	shaderRID = rd.shader_create_from_spirv(shaderSpirv) #setup the shader RID
	pipeline = rd.compute_pipeline_create(shaderRID) #create the pipeline
	
	#making input data
	
	inputBytes = makeBufferArray(initialData)
	outputBytes = inputBytes
	constantInts = [10,width,timestep]
	
	constBytes.resize(16)
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	matDictBytes = matDictToBytes(matDict)
	
	
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
	
func loadingJsonFile(path : String):
	var file = FileAccess.open(path,FileAccess.READ)
	var text = file.get_as_text()
	var json_result = JSON.parse_string(text)
	return json_result

func matDictToBytes(dict : Dictionary):
	var propertiesDict = loadingJsonFile("res://materials/materialsProperties.json")
	var arrayForm := PackedByteArray([])
	arrayForm.resize(2048)
	for i in dict.keys():
		if dict.get(i,null) != null:
			var mat = dict[i]
			var properties = propertiesDict[mat]
			arrayForm.encode_double(i*32,properties["specificHeat"])
			arrayForm.encode_double(i*32+8,properties["conductivity"])
			arrayForm.encode_double(i*32+16,properties["density"]/1000)
			#the missing i*32+24 is blank data cuase its useless for stupid reasons
	return arrayForm

func makeBufferArray(data:Array) -> PackedByteArray:
	width = data[0][0]["width"]
	matDict = data[0][1]
	var newData := PackedByteArray()
	newData.resize(len(data[1]) * 16)
	for i in range(0,len(data[1])):
		newData.encode_u32(i*12,data[1][i][0])
		newData.encode_double(i*12 + 4,data[1][i][1].get("temperature",0))
	return newData
	
func outputGrid(buffer : PackedByteArray) -> void:
	@warning_ignore("integer_division")
	for i in range(0,len(buffer)/(16*width)):
		var toPrint = []
		toPrint.append("Row: " + str(i))
		for j in range(0,width):
			toPrint.append(str(buffer.decode_u64(i*width*12 + j*12)) + ", temp:" + str(buffer.decode_double(i*width*12 + j*12 + 4 )))
		print(toPrint)
	
func _ready() -> void:
	shaderSetup()
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
	rd.submit()
	rd.sync()
	var outputValues = get_output(rd,outBufferRID)
	rd.buffer_update(inBufferRID,0,outputValues.size(),outputValues)
	rdManager.runShader(rd,pipeline,{0 : uniformSet},workGroups)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_dellta: float) -> void:
	if run < 10:
		outputGrid(get_output(rd,outBufferRID))
		print("output")
		_runShader()
		outputGrid(get_output(rd,outBufferRID))
		print(get_output(rd,constRID).to_int64_array())
		run += 1
	elif run <= 10:
		freeRIDS()
		run +=1
	else:
		pass


func changeTimeScale(button : Button) -> void:
	print(button)
	timestep = (button.get_index()-1) * 7200
	print(timestep)
	constantInts = [10,timestep,width]
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	rd.buffer_update(constRID,0,constBytes.size(),constBytes)
