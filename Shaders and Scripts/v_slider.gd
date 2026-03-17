extends VSlider


func _ready() -> void:
	var nuke = get_node(^"/root/mainNode/Sim/nuclear")
	value_changed.connect(nuke.controlRodMoved).
