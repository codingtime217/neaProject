extends VSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var nuke = get_node(^"/root/mainNode/Sim/nuclear")
	value_changed.connect(nuke.controlRodMoved)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
