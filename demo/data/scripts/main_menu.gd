extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_interactive_grid_2d_pressed() -> void:
	get_tree().change_scene_to_file("res://data/scenes/interactive_grid_2d_demo/main.tscn")


func _on_button_interactive_grid_3d_pressed() -> void:
	get_tree().change_scene_to_file("res://data/scenes/interactive_grid_3d_demo/main.tscn")
