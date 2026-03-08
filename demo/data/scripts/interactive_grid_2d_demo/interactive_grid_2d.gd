extends InteractiveGrid2D

@onready var button: Button = $"../../UserInterface/Start/Button"
@onready var user_interface: CanvasLayer = $"../../UserInterface"

var _actor: CharacterBody2D = null
var _path: PackedInt64Array = []

func _ready() -> void:
	for cell in get_node("/root/Main/World/Cells").get_children():
		if cell.has_node("ActorPlayer"):
			_actor = cell.get_node("ActorPlayer") as CharacterBody2D
			self.set_actor(_actor)
			break
	
func _process(delta: float) -> void:
	if _actor == null: return
	
	if self.get_selected_cells().is_empty():
		_actor.idle()
		self.highlight_on_hover(get_global_mouse_position())
	else:
		move_along_path(_path)

func _input(event):
	if event.is_action_pressed("show_grid"):
		if _actor: 
			self.show_grid()
			button.visible = false
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _actor == null: 
			return

		var selected_cells: Array = self.get_selected_cells()
		if selected_cells.size() < 1:
			var hit_cell_index = self.get_cell_index_from_global_position(get_global_mouse_position())
			self.select_cell(hit_cell_index)
			selected_cells = self.get_selected_cells()
			if selected_cells.is_empty():
				return

			var pawn_current_cell_index: int = self.get_cell_index_from_global_position(self.global_position)
			self.set_cell_accessible(pawn_current_cell_index, true)
			_path = self.get_path(pawn_current_cell_index, selected_cells[0])
			print("Last selected cell:", self.get_latest_selected())
			print("Path:", _path)
			self.highlight_path(_path)
			
			
func move_along_path(path: PackedInt64Array)-> void:
	if path.is_empty():
		show_grid()
		return
	
	var target_cell_index: int = path[0]
	var target_global_position: Vector2 = get_cell_global_position(target_cell_index)
	if not is_on_target_cell(_actor.global_position, target_global_position, 32):
		reaching_cell_target(target_cell_index)
	else:
		target_cell_reached()

func show_grid():
	#region InteractiveGrid3D Center
	## Here, the grid is centered around the player.
	## !Note: This operation repositions all cells, aligns them with the environment,
	## rescans obstacles and custom data, and refreshes A* navigation.
	##  - Manual modifications can also be applied here, such as:
	##     - Hiding cells beyond a certain distance
	##     - compute_unreachable_cells
	##     - Adding custom data

	if _actor == null: return

	_path = []
	self.set_visible(true)
	self.center(_actor.global_position)
	
	var actor_current_cell_index: int = self.get_cell_index_from_global_position(_actor.global_position)
	print("_actor.global_position", _actor.global_position)
	print("_actor_current_cell_index", actor_current_cell_index)
	
	# To prevent the player from getting stuck.
	self.set_cell_accessible(actor_current_cell_index, true)
	self.set_cell_reachable(actor_current_cell_index, true)

	self.hide_distant_cells(actor_current_cell_index, 600)
	self.compute_unreachable_cells(actor_current_cell_index)

	#var neighbors: PackedInt64Array = self.get_neighbors(actor_current_cell_index)
	#for neighbor_index in neighbors:
	#	self.add_custom_cell_data(neighbor_index, "CFL_NEIGHBORS")

	self.add_custom_cell_data(actor_current_cell_index, "CFL_PLAYER")
	
	## !Note: Don't forget to call update_custom_data().
	## It refreshes custom_cell_flags, colors, and the A* configuration
	## based on the newly updated CellCustomData.
	#self.update_custom_data()
	#endregion
	
func reaching_cell_target(target_cell_index: int) -> void:
	if _path.size() > 0:
		var target_cell_global_position: Vector2 = self.get_cell_global_position(target_cell_index)
		if _actor.has_method("move_to"):
			_actor.move_to(target_cell_global_position)
		else:
			printerr("actor does not have the 'move_to' method.")
		
		
func target_cell_reached():
	if not _path.is_empty():
		_path.remove_at(0)


static func is_on_target_cell(current_global_position: Vector2, target_global_position: Vector2, threshold: float) -> bool:
	return current_global_position.distance_to(target_global_position) <= threshold


func set_actor(actor: CharacterBody2D):
	_actor = actor
	
	
func _on_button_pressed() -> void:
	show_grid()
	button.visible = false
