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
	inputBytes = makeBufferArray(initalData[1])
	width = initalData[0][0]["width"]
	var matDict = initalData[0][1]
	matDictBytes = matDictToBytes(matDict)
	
	
	constantInts = [10,width,1]
	constBytes.resize(16)
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	matDictBytes = matDictToBytes(matDict)

func makeBufferArray(data:Array) -> PackedByteArray:
	var newData := PackedByteArray()
	newData.resize(len(data) * 16)
	@warning_ignore("integer_division")
	height = len(data)/ width
	for i in range(0,len(data)):
		newData.encode_u32(i*16,data[i][0])
		newData.encode_double(i*16 + 8,data[i][1].get("temperature",0))
	return newData
	
	
func matDictToBytes(dict : Dictionary):
	var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd")
	var materialDict = jsonLoader.loadingJsonFile("res://materials/materialsProperties.json")
	var arrayForm := PackedByteArray([])
	arrayForm.resize(2048)
	for i in dict.keys():
		if i == "void":
			continue
		elif dict.get(i,null) != null:
			var mat = dict[i]
			var properties = materialDict[mat]
			if properties["fissile"] == true:
				arrayForm.encode_double(i*32,properties["thermalCrossSection"])
				arrayForm.encode_double(i*32+8,properties["averageNeutrons"])
				arrayForm.encode_float(i*32+16,properties["neutronEnergy"])
				arrayForm.encode_double(i*32+20,properties["deltaE"])
			arrayForm.encode_float(i*32 + 28,properties["moderationFactor"])
			arrayForm.encode_double(i*32 + 32,properties["moderationCrossSection"])
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
	
	
	pipeline1 = pipelineSetup(rd,shaderPath1,uniformSet1)
	pipeline2 = pipelineSetup(rd,shaderPath2,uniformSet2)
	
	
	
func pipelineSetup(renderDevice : RenderingDevice,shaderPath : String,uniformSet : RID) ->  RID:
	var spirv = rdManager.importShaderFromFile(shaderPath)
	var shaderRID = renderDevice.shader_create_from_spirv(spirv)
	var pipeline = renderDevice.compute_pipeline_create(shaderRID)
	uniformSet = renderDevice.uniform_set_create([inUniform,constUniform,matUniform,outUniform],shaderRID,0)
	return pipeline

func runShader() -> void:
	rdManager.runShader(rd,pipeline1,{0: uniformSet1},workGroups)
	rd.submit()
	rd.sync()
	var output = rd.buffer_get_data(outBufferRID)
	rd.buffer_update(inBufferRID,0,output.size(),output)
	rdManager.runShader(rd,pipeline2,{0: uniformSet2},workGroups)
	rd.submit()
	rd.sync()



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
