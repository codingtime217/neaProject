extends Node2D
@export_file var shaderPath : String

#rendering device, work groups and shaderRID defines
var rdManager = load("res://Shaders and Scripts/shaderManager.gd").new()
@export var workGroups := Vector3i(1,1,1)
var rd : RenderingDevice
var shaderRID : RID

var initialData : Array
var timestep := 60
#declaring inputs and other buffer values
var input : PackedFloat64Array
var inputBytes : PackedByteArray
var width : int
var height : int
var constantInts : Array
var constBytes := PackedByteArray()
var output : PackedFloat64Array
var outputBytes : PackedByteArray
var matDictBytes : PackedByteArray
#pre declaring RIDs and Uniforms
var constRID : RID
var matRID : RID
var inBufferRID : RID
var outBufferRID : RID
var inUniform : RDUniform
var matUniform : RDUniform
var constUniform : RDUniform
var outUniform : RDUniform
#last two RIDS
var uniformSet : RID
var pipeline : RID


func matDictToBytes(dict : Dictionary): #convers the materials dictionary to bytes
	var jsonLoader = load("res://Shaders and Scripts/jsonLoader.gd")
	var materialDict = jsonLoader.loadingJsonFile("res://materials/materialsProperties.json") #load the properties dictionary
	var arrayForm := PackedByteArray([])
	arrayForm.resize(1024) #has fixed size so this should be more than enough
	for i in dict.keys():
		if dict.get(i,null) != null:
			var mat = dict[i] #get the current materials properties
			var properties = materialDict[mat]
			#encode its properties as binary data
			arrayForm.encode_double(i*32,properties["specificHeat"])
			arrayForm.encode_double(i*32+8,properties["conductivity"])
			arrayForm.encode_double(i*32+16,properties["density"]/1000)
			#the missing 8 bytes is blank data as the buffers have to take data in 16 byte sections
	return arrayForm #return the byes array


func dataSetup(initalData) -> void: 
	width = initalData[0][0]["width"] #seperate the width
	inputBytes = makeBufferArray(initalData[1]) #conver the input into bytes
	outputBytes = inputBytes #set the output equal to input for simplicity so its the right size
	var matDict = initalData[0][1]
	matDictBytes = matDictToBytes(matDict) #conver the material Dictionary to bytes
	#set the workgroups to be 1 per tile
	workGroups = Vector3(width,height,1)
	#converting constants to a byte array
	constantInts = [10,width,1] 
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
	
	#setting up uniforms and buffers by defining them and giving them the data
	constRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,constBytes.size(),constBytes)
	inBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,inputBytes.size(),inputBytes)
	outBufferRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,outputBytes.size(),outputBytes)
	matRID = rdManager.createBufferRID(rd,RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,matDictBytes.size(),matDictBytes)
	
	#create uniforms for the buffers
	inUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,0,inBufferRID)
	constUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,1,constRID)
	matUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER,2,matRID)
	outUniform = rdManager.createUniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER,3,outBufferRID)
	#create a uniform set contain all the buffers at the correct indexes
	uniformSet = rd.uniform_set_create([inUniform,constUniform,matUniform,outUniform],shaderRID,0) #creates the set	
	
func get_output(rendering : RenderingDevice, buffer : RID) -> PackedByteArray: #returns the data in a buffer
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
	
	
func makeItBackIntoTheArray(data : PackedByteArray) -> Array: #converts packed byte data back into the array form
	var returnArray = []
	@warning_ignore("integer_division")
	for i in range(0,len(data)/16): #goes through each 16 byte block (as that corresponds to one tile)
		var matIndex = data.decode_u32(i*16) #decodes the material index
		var thermalEnergy = data.decode_double(i*16 + 8) #decodes the thermal Energy
		returnArray.append([matIndex,{"thermalEnergy" : thermalEnergy}]) #appends it to the array
	return returnArray
	
func _ready() -> void: #load the time scale buttons and connect them
	var buttonGroup = load("res://UI Themes and Schemes/speedControlsGroup.tres")
	buttonGroup.pressed.connect(changeTimeScale)
	
func freeRIDS() -> void:
	#frees all the rids to prevent unneeded memeory usage
	rd.free_rid(inBufferRID)
	rd.free_rid(outBufferRID)
	rd.free_rid(constRID)
	rd.free_rid(shaderRID)

func _runShader() -> void: #runs the shader
	for i in range(timestep): #running it several times instead of differenece*timestep to avoid weirdness ie massive jumps in values
		rdManager.runShader(rd,pipeline,{0 : uniformSet},workGroups) #run the shader with the inputs
		rd.submit()#submit the data
		rd.sync() #wait for the shader to finish
		var outputValues = get_output(rd,outBufferRID)
		rd.buffer_update(inBufferRID,0,outputValues.size(),outputValues)
func returnOutput() -> Array:#return the data from the output buffer
	return makeItBackIntoTheArray(get_output(rd,outBufferRID))

func updateInput(newInputData) -> void:
	inputBytes = makeBufferArray(newInputData) #make a new input buffer out of the data
	rd.buffer_update(inBufferRID,0,inputBytes.size(),inputBytes) #update the input buffer
	
func changeTimeScale(button : Button) -> void: #changes the timestep buffer value
	timestep = (button.get_index()-1) * 360
	constantInts = [10,width,1]
	for i in range(len(constantInts)):
		if constantInts[i] < 0:
			constantInts[i] *= -1
		constBytes.encode_u32(i*4,constantInts[i])
	rd.buffer_update(constRID,0,constBytes.size(),constBytes)
