extends Camera2D

func _process(_delta: float) -> void: #called every frame
	
	if Input.is_action_pressed("camera_drag"): #if they pressed the key to move the camera
		global_position = get_global_mouse_position() #move the camera to the mouse
