extends Node2D
#shader overall stuff
var rdManager = load("res://Shaders and Scripts/shaderManager.gd").new()
@export var workGroups := Vector3i(1,1,1)
var rd : RenderingDevice
var shaderRID1 : RID
var pipeline1 : RID
var shaderRID2 : RID
var pipeline2 : RID
@export var shaderPath1 : String
@export var shaderPath2	: String

var initialData : Array
var timestep := 60
var controlRodInsertion : float
#data properties
var input : PackedFloat64Array
var inputBytes : PackedByteArray
var width : int
var height : int
var constantInts : Array
var constBytes := PackedByteArray()
var output : PackedFloat64Array
var outputBytes : PackedByteArray
var matDict : Dictionary
var matDictBytes : PackedByteArray
#RIDs and uniforms
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

func _ready() -> void: #connect to timescale button
	var buttonGroup = load("res://UI Themes and Schemes/speedControlsGroup.tres")
	buttonGroup.pressed.connect(changeTimeScale)

func dataSetup(initalData) -> void: #conver the data array into bytes and do the setup
	width = initalData[0][0]["width"] #get the grid width
	controlRodInsertion = 0.1 #inital value
	matDict = initalData[0][1] #get the material dictionary
	matDictBytes = matDictToBytes(matDict) #turn it to bytes
	inputBytes = makeBufferArray(initalData[1]) #make the input buffer
	workGroups = Vector3(width,height,1) #set the workgroups
	#constants stuff
	constantInts = [10,width,1]
	constBytes.resize(16)
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	outputBytes = inputBytes #set ouput to input initially
	
	
func controlRodMoved(newPosition) -> void: #update the control rod position
	controlRodInsertion = newPosition
	
func makeBufferArray(data:Array) -> PackedByteArray: #turn the tile data into the binary array
	var newData := PackedByteArray()
	newData.resize(len(data) * 32) #make the array the right size as it is 32 bytes per tile
	@warning_ignore("integer_division")
	height = len(data)/ width
	var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd")
	var materialDict = jsonLoader.loadingJsonFile("res://materials/materialsProperties.json")
	for i in range(0,len(data)): #go through in order encoding the data
		newData.encode_u32(i*32,data[i][0])
		var materialProp = materialDict[matDict[data[i][0]]]
		if materialProp.get("control",false) == true:
			#control rods use fissile density to determine the insertion level
			newData.encode_float(i*32 + 4,materialProp.get("atomDensity") * (1-controlRodInsertion))
		else:
			#otherwise use the tile vallue
			newData.encode_float(i*32 + 4,data[i][1].get("fissileDensity",0))
		newData.encode_double(i*32 + 8,data[i][1].get("fastNeutronFlux",0))
		newData.encode_double(i*32 + 16,data[i][1].get("thermalNeutronFlux",0))
		newData.encode_double(i*32 + 24,data[i][1].get("thermalEnergy",0))
	return newData
	
	
func matDictToBytes(dict : Dictionary): #make the material dictionary into bytes
	var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd")
	var materialDict = jsonLoader.loadingJsonFile("res://materials/materialsProperties.json")
	var arrayForm := PackedByteArray([])
	arrayForm.resize(2048) #buffer is larger than thermal as twice as much data needed per material
	for i in dict.keys():
		if i == 0:
			# if it is void then they're all 0
			continue
		elif dict.get(i,null) != null:
			var mat = dict[i]
			var properties = materialDict[mat]
			if properties["fissile"] == true: #if its not fissile these will be 0
				arrayForm.encode_double(i*64,properties["thermalCrossSection"])
				arrayForm.encode_double(i*64+8,properties["averageNeutrons"])
				arrayForm.encode_double(i*64+16,properties["neutronEnergy"])
				arrayForm.encode_double(i*64+24,properties["deltaE"])
			#these every material will need
			arrayForm.encode_double(i*64 + 32,properties.get("moderationFactor",0)) #if not present encode a 0
			arrayForm.encode_double(i*64 + 40,properties.get("moderationCrossSection",0))
			arrayForm.encode_double(i*64 + 48,properties.get("absorbtionCrossSection",0))
			arrayForm.encode_double(i*64 + 56,properties.get("atomDensity",0))
	return arrayForm



func setup():
	rd = RenderingServer.create_local_rendering_device() #make the rendeing device
	
	#make the RIDS
	constRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,constBytes.size(),constBytes)
	inBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,inputBytes.size(),inputBytes)
	outBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,outputBytes.size(),outputBytes)
	matRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,matDictBytes.size(),matDictBytes)
	#Use the rids to define uniforms
	inUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0,inBufferRID)
	constUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,1,constRID)
	matUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,2,matRID)
	outUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,3,outBufferRID)
	
	#make the pipelines, uniform sets and shaderRIDs
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
	#sets up one shader pipeline, unfirom set and RID 
	var spirv = rdManager.importShaderFromFile(shaderPath) #get the shader SPIRc
	var shaderRID = renderDevice.shader_create_from_spirv(spirv)#use that to make the RID and pipeline
	var pipeline = renderDevice.compute_pipeline_create(shaderRID)
	#create the unifrom set
	var uniformSet = renderDevice.uniform_set_create([inUniform,constUniform,matUniform,outUniform],shaderRID,0)
	assert(pipeline != null) #check the pipeline worked
	return [pipeline,uniformSet,shaderRID] #return the 3 as an array

func _runShader() -> void: #runs the shaders in order
	rdManager.runShader(rd,pipeline1,{0: uniformSet1},workGroups) #run first shader
	rd.submit()
	rd.sync()
	var newData = rd.buffer_get_data(outBufferRID) #use the data to update the 2nd
	rd.buffer_update(inBufferRID,0,newData.size(),newData)
	rdManager.runShader(rd,pipeline2,{0: uniformSet2},workGroups)#run the 2nd
	rd.submit()
	rd.sync()
	newData = rd.buffer_get_data(outBufferRID)

func returnOutput() -> Array:
	var temp = makeItBackIntoTheArray(get_output(rd,outBufferRID))
	return temp

func makeItBackIntoTheArray(data : PackedByteArray) -> Array: #convers the data from binary back to the array of dictionaries
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
	inputBytes = makeBufferArray(newInputData) #updates the input
	rd.buffer_update(inBufferRID,0,inputBytes.size(),inputBytes)


func free_RIDS() ->void:
	#this is run when the node leaves the tree
	#frees RIDs to avoid memeory leaks
	rd.free_rid(inBufferRID)
	rd.free_rid(outBufferRID)
	rd.free_rid(constRID)
	rd.free_rid(pipeline1)
	rd.free_rid(pipeline2)

func changeTimeScale(button : Button) -> void: #updates the timescale
	timestep = (button.get_index()-1) * 360
	constantInts = [10,width,1]
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	rd.buffer_update(constRID,0,constBytes.size(),constBytes)
