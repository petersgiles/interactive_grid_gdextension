#**************************************************************************#
#*  interactive_grid_3d.gd                                                *#
#**************************************************************************#
#*                         This file is part of:                          *#
#*                     INTERACTIVE GRID GDExtension                       *#
#*         https://github.com/antoinecharruel/interactive_grid            *#
#**************************************************************************#
#* Copyright (c) 2025 Antoine Charruel.                                   *#
#*                                                                        *#
#* Permission is hereby granted, free of charge, to any person obtaining  *#
#* a copy of this software and associated documentation files (the        *#
#* "Software"), to deal in the Software without restriction, including    *#
#* without limitation the rights to use, copy, modify, merge, publish,    *#
#* distribute, sublicense, and/or sell copies of the Software, and to     *#
#* permit persons to whom the Software is furnished to do so, subject to  *#
#* the following conditions:                                              *#
#*                                                                        *#
#* The above copyright notice and this permission notice shall be         *#
#* included in all copies or substantial portions of the Software.        *#
#*                                                                        *#
#* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        *#
#* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     *#
#* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. *#
#* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   *#
#* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   *#
#* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      *#
#* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 *#
#**************************************************************************#

extends InteractiveGrid3D

@onready var ray_cast_from_mouse: RayCast3D = $"../RayCastFromMouse"
@onready var button: Button = $"../UserInterface/Start/Button"

var _path: PackedInt64Array = []
var _actor: CharacterBody3D = null


func _ready() -> void:
	var cells = get_node("/root/Main/World/Cell").get_children()
	
	for cell in cells:
		var actors_node = cell.get_node_or_null("Actors")
		if actors_node and actors_node.has_node("ActorPlayer"):
			_actor = actors_node.get_node("ActorPlayer") as CharacterBody3D
			break

func _process(delta: float) -> void:
	if _actor == null: return
	
	if self.get_selected_cells().is_empty():
		_actor.idle()
		self.highlight_on_hover(ray_cast_from_mouse.get_ray_intersection_position())
	else:
		move_along_path(_path)


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
	
	var pawn_current_cell_index: int = self.get_cell_index_from_global_position(_actor.global_position)

	# To prevent the player from getting stuck.
	self.set_cell_accessible(pawn_current_cell_index, true)
	self.set_cell_reachable(pawn_current_cell_index, true)

	self.hide_distant_cells(pawn_current_cell_index, 6)
	self.compute_unreachable_cells(pawn_current_cell_index)

	var neighbors: PackedInt64Array = self.get_neighbors(pawn_current_cell_index)
	for neighbor_index in neighbors:
		self.add_custom_cell_data(neighbor_index, "CFL_NEIGHBORS")

	self.add_custom_cell_data(pawn_current_cell_index, "CFL_PLAYER")
	
	## !Note: Don't forget to call update_custom_data().
	## It refreshes custom_cell_flags, colors, and the A* configuration
	## based on the newly updated CellCustomData.
	self.update_custom_data()
	#endregion


func _input(event):
	if event.is_action_pressed("show_grid") and button.visible:
		self.show_grid()
		button.visible = false
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _actor == null: 
			return

		var ray_pos: Vector3 = ray_cast_from_mouse.get_ray_intersection_position()
		if ray_pos == null: 
			return

		var selected_cells: Array = self.get_selected_cells()
		if selected_cells.size() < 1:
			var hit_cell_index = self.get_cell_index_from_global_position(ray_pos)
			self.select_cell(hit_cell_index)
			selected_cells = self.get_selected_cells()
			if selected_cells.is_empty():
				return

			var pawn_current_cell_index: int = self.get_cell_index_from_global_position(_actor.global_position)
			self.set_cell_accessible(pawn_current_cell_index, true)
			_path = self.get_path(pawn_current_cell_index, selected_cells[0])
			print("Last selected cell:", self.get_latest_selected())
			print("Path:", _path)
			self.highlight_path(_path)


func move_along_path(path: PackedInt64Array)-> void:
	if path.is_empty():
		_actor.idle()
		show_grid()
		return
	
	var target_cell_index: int = path[0]
	var target_global_position: Vector3 = get_cell_global_position(target_cell_index)
	if not is_on_target_cell(_actor.global_position, target_global_position, 0.20):
		reaching_cell_target(target_cell_index)
	else:
		target_cell_reached()


func reaching_cell_target(target_cell_index: int) -> void:
	if _path.size() > 0:
		var target_cell_global_position: Vector3 = self.get_cell_global_position(target_cell_index)
		if _actor.has_method("move_to"):
			_actor.move_to(target_cell_global_position)
		else:
			printerr("pawn does not have the 'move_to' method.")


func target_cell_reached():
	if not _path.is_empty():
		_path.remove_at(0)


static func is_on_target_cell(current_global_position: Vector3, target_global_position: Vector3, threshold: float) -> bool:
	return current_global_position.distance_to(target_global_position) <= threshold


func set_actor(pawn: CharacterBody3D):
	_actor = pawn


func _on_button_pressed() -> void:
	show_grid()
	button.visible = false
