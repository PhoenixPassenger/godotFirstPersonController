class_name State
extends Node

signal finished(next_state_name)

var state_machine: ControllableNodeStateMachine = null
var actor: Node = null

func _ready() -> void:
	pass

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
