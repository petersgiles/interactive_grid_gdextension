extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree

var input_vector = Vector2.ZERO

const SPEED:float = 300.0

func _ready() -> void:
	pass
	
	
func _physics_process(delta: float) -> void:
	pass

func move_to(p_global_position: Vector2) -> void:
	var to_target: Vector2 = p_global_position - global_position
		
	var direction := to_target.normalized()
	velocity = direction * SPEED

	direction.y = 0
	input_vector = direction
	update_blend_position(direction)

	move_and_slide()


func update_blend_position(direction_vector: Vector2) -> void:
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", direction_vector)
	
func idle():
	input_vector = Vector2.ZERO


func _on_button_button_down() -> void:
	pass
