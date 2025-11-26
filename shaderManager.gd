extends Node2D

func importShaderFromFile(path : String) -> RDShaderSPIRV:
	var shaderFile = load(path) #loads the file
	assert(shaderFile != null, "Shader not imported correctly") #check the file exists and is the correct format
	var spirv : RDShaderSPIRV = shaderFile.get_spirv() #converts to SPIRVE
	assert(spirv.compile_error_compute.is_empty())
	assert(spirv != null, "spirv is null") #checks for compile errors
	return spirv # returns SPIRV

func createBufferRID(rd : RenderingDevice, type : RenderingDevice.UniformType, size : int, bytes : PackedByteArray) -> RID:
	var buffer : RID #creates RID
	if type == RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER:
		buffer = rd.storage_buffer_create(size,bytes) #makes the RID a storage buffer
	else:
		buffer = rd.uniform_buffer_create(size,bytes) #makes the RID a uniform buffer
	assert(buffer.is_valid(),"Invlaid buffer") #check its valid
	return buffer #return the RID
	
func createUniform(type : RenderingDevice.UniformType, binding : int, buffer : RID) -> RDUniform:
	var uniform = RDUniform.new() #make a new uniform
	uniform.binding = binding	#set the bindings and types
	uniform.uniform_type = type
	uniform.add_id(buffer) #assign it the buffer
	return uniform #return the uniform
				
func bindUnifromSet(rd : RenderingDevice, compileList, unifromSet : RID, setId : int) -> void:
	rd.compute_list_bind_uniform_set(compileList,unifromSet,setId)

func run_shader(rd : RenderingDevice, pipeline : RID, uniformSets : Dictionary, workGroups : Vector3i ) -> void: #unifrom sets is a dictionary of {setID: unifromSet}
	var compileList = rd.compile_list_begin()
	rd.compute_list_bind_compute_pipeline(compileList, pipeline)
	for i in uniformSets.keys():
		bindUnifromSet(rd,compileList,uniformSets[i],i)
	rd.compute_list_dispatch(compileList,workGroups.x,workGroups.y,workGroups.z)
	rd.compute_list_end()
	

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
