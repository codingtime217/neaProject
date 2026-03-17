extends VSlider

func _ready() -> void: #connects to the nuclear shader manager so it can update the control rod insertion
	var nuke = get_node(^"/root/mainNode/Sim/nuclear")
	value_changed.connect(nuke.controlRodMoved)
