extends Node
signal move_input(Vector2)
signal jump_pressed
signal interact_pressed

func _process(_delta):
	var move_vec = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("backwards") - Input.get_action_strength("forward")
	)
	emit_signal("move_input", move_vec, _delta)
	
	if Input.is_action_just_pressed("jump"):
		emit_signal("jump_pressed")
	if Input.is_action_just_pressed("interact"):
		emit_signal("interact_pressed")
