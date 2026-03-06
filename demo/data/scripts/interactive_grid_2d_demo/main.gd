extends Node2D

@onready var user_interface: Control = $UserInterface

var _main_actor: CharacterBody2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for cell in get_node("/root/Main/World/Cell").get_children():
		if cell.has_node("ActorPlayer"):
			_main_actor = cell.get_node("ActorPlayer") as CharacterBody2D
			break


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	user_interface.position = _main_actor.position
