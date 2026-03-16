extends Node2D
var rdManager = load("res://Shaders and Scripts/shaderManager.gd").new()
@export var workGroups := Vector3i(1,1,1)
var rd : RenderingDevice
var shaderRID1 : RID
var pipeline1 : RID

@export var shaderPath1 : String
@export var shaderPath2	: String


var rdStage2 : RenderingDevice
var shaderRID2 : RID
var pipeline2 : RID

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

var uniformSet1 : RID
var uniformSet2: RID
var run = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var buttonGroup = load("res://UI Themes and Schemes/speedControlsGroup.tres")
	buttonGroup.pressed.connect(changeTimeScale)

func dataSetup(initalData) -> void:
	width = initalData[0][0]["width"]
	inputBytes = makeBufferArray(initalData[1])
	var matDict = initalData[0][1]
	matDictBytes = matDictToBytes(matDict)
	
	constantInts = [10,width,1]
	constBytes.resize(16)
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	matDictBytes = matDictToBytes(matDict)
	outputBytes = inputBytes
	
	
func makeBufferArray(data:Array) -> PackedByteArray:
	#print(data)
	var newData := PackedByteArray()
	newData.resize(len(data) * 32)
	@warning_ignore("integer_division")
	height = len(data)/ width
	for i in range(0,len(data)):
		newData.encode_u32(i*32,data[i][0])
		newData.encode_float(i*32 + 4,data[i][1].get("fissileDensity",0))
		newData.encode_double(i*32 + 8,data[i][1].get("fastNeutronFlux",0))
		newData.encode_double(i*32 + 16,data[i][1].get("thermalNeutronFlux",0))
		newData.encode_double(i*32 + 24,data[i][1].get("thermalEnergy",0))
	print(newData)
	return newData
	
	
func matDictToBytes(dict : Dictionary):
	var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd")
	var materialDict = jsonLoader.loadingJsonFile("res://materials/materialsProperties.json")
	var arrayForm := PackedByteArray([])
	arrayForm.resize(2048)
	for i in dict.keys():
		if i == 0:
			continue
		elif dict.get(i,null) != null:
			var mat = dict[i]
			var properties = materialDict[mat]
			if properties["fissile"] == true:
				arrayForm.encode_double(i*64,properties["thermalCrossSection"])
				arrayForm.encode_double(i*64+8,properties["averageNeutrons"])
				arrayForm.encode_double(i*64+16,properties["neutronEnergy"])
				arrayForm.encode_double(i*64+24,properties["deltaE"])
			arrayForm.encode_double(i*64 + 32,properties.get("moderationFactor",0))
			arrayForm.encode_double(i*64 + 40,properties.get("moderationCrossSection",0))
			arrayForm.encode_double(i*64 + 32,properties.get("absorbtionCrossSection",0))
			arrayForm.encode_double(i*64 + 40,properties.get("atomDensity",0))
	return arrayForm



func setup():
	rd = RenderingServer.create_local_rendering_device()
	
	
	constRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,constBytes.size(),constBytes)
	inBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,inputBytes.size(),inputBytes)
	outBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,outputBytes.size(),outputBytes)
	matRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,matDictBytes.size(),matDictBytes)
	
	inUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0,inBufferRID)
	constUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,1,constRID)
	matUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,2,matRID)
	outUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,3,outBufferRID)
	
	
	var temp = pipelineSetup(rd,shaderPath1)
	pipeline1 = temp[0]
	uniformSet1 = temp[1]
	shaderRID1 = temp[2]
	temp = pipelineSetup(rd,shaderPath2)
	pipeline2 = temp[0]
	uniformSet2 = temp[1]
	shaderRID2 = temp[2]
	
	
func get_output(rendering : RenderingDevice, buffer : RID) -> PackedByteArray:
	var outputAsBytes := rendering.buffer_get_data(buffer)
	return outputAsBytes
	
	
func pipelineSetup(renderDevice : RenderingDevice,shaderPath : String) ->  Array:
	var spirv = rdManager.importShaderFromFile(shaderPath)
	var shaderRID = renderDevice.shader_create_from_spirv(spirv)
	var pipeline = renderDevice.compute_pipeline_create(shaderRID)
	var uniformSet = renderDevice.uniform_set_create([inUniform,constUniform,matUniform,outUniform],shaderRID,0)
	assert(pipeline != null)
	return [pipeline,uniformSet,shaderRID]

func _runShader() -> void:
	rdManager.runShader(rd,pipeline1,{0: uniformSet1},workGroups)
	rd.submit()
	rd.sync()
	var newData = rd.buffer_get_data(outBufferRID)
	print(newData)
	print("step1 data: ", makeItBackIntoTheArray(newData))
	rd.buffer_update(inBufferRID,0,newData.size(),newData)
	#rdManager.runShader(rd,pipeline2,{0: uniformSet2},workGroups)
	#rd.submit()
	#rd.sync()

func returnOutput() -> Array:
	var temp = makeItBackIntoTheArray(get_output(rd,outBufferRID))
	return temp

func makeItBackIntoTheArray(data : PackedByteArray) -> Array:
	var returnArray = []
	@warning_ignore("integer_division")
	for i in range(0,len(data)/32):
		var matIndex = data.decode_u32(i*32)
		var fissileD =  data.decode_float(i*32 + 4)
		var fastNFlux = data.decode_double(i*32 + 8)
		var thermalNFlux = data.decode_double(i*32 + 16)
		var thermalE =  data.decode_double(i*32 + 24)
		returnArray.append([matIndex,{"thermalEnergy" : thermalE,"fastNeutronFlux" : fastNFlux, "thermalNeutronFlux" : thermalNFlux,"fissileDensity" : fissileD}])
	return returnArray


func updateInput(newInputData) -> void:
	inputBytes = makeBufferArray(newInputData) #this does work
	rd.buffer_update(inBufferRID,0,inputBytes.size(),inputBytes)


func free_RIDS() ->void:
	rd.free_rid(inBufferRID)
	rd.free_rid(outBufferRID)
	rd.free_rid(constRID)
	rd.free_rid(pipeline1)
	rd.free_rid(pipeline2)



func changeTimeScale(button : Button) -> void:
	timestep = (button.get_index()-1) * 60
	constantInts = [10,width,1]
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	rd.buffer_update(constRID,0,constBytes.size(),constBytes)
