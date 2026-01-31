extends GutTest

const TEST_SCENE = preload("res://test/scenes/test_interactive_grid_3d.tscn")

var test_scene: Node
var interactive_grid_3d: InteractiveGrid3D

func before_each()->void:
	test_scene = TEST_SCENE.instantiate()
	add_child(test_scene)
	await get_tree().process_frame
	interactive_grid_3d = test_scene.get_node("InteractiveGrid3D") as InteractiveGrid3D
	assert_not_null(interactive_grid_3d, "InteractiveGrid3D node should exist")
	
	while not interactive_grid_3d.is_created():
		await get_tree().process_frame
	await wait_seconds(0.25)
	
	
func after_each()->void:
	await wait_seconds(0.25)
	if test_scene:
		test_scene.queue_free()
		
		
func test_add_custom_cell_data():
	interactive_grid_3d.add_custom_cell_data(0, "CFL_GREEN")
	assert_true(interactive_grid_3d.has_custom_cell_data(0, "CFL_GREEN"), "Custom cell data 'CFL_GREEN' should be added to cell 0")
	
	
func test_center():
	interactive_grid_3d.center(Vector3(-10.0,0.0,-10.0))
	var center_global_position: Vector3 = interactive_grid_3d.global_position
	assert_eq(center_global_position, Vector3(-10.0,0.0,-10.0), "Grid center global position should match the given position")
	
	
func test_clear_all_custom_cell_data():
	interactive_grid_3d.add_custom_cell_data(0, "CFL_GREEN")
	interactive_grid_3d.clear_all_custom_cell_data(0)
	assert_false(interactive_grid_3d.has_custom_cell_data(0, "CFL_GREEN"), "All custom cell data should be cleared from cell 0")
	
	
func test_clear_custom_cell_data():
	interactive_grid_3d.add_custom_cell_data(0, "CFL_GREEN")
	interactive_grid_3d.clear_custom_cell_data(0, "CFL_GREEN", true)
	assert_false(interactive_grid_3d.has_custom_cell_data(0, "CFL_GREEN"), "Custom cell data 'CFL_GREEN' should be removed from cell 0")
	
	
func test_get_cell_global_position():
	interactive_grid_3d.center(Vector3(-10.0, 0.0, -10.0))

	var pos := interactive_grid_3d.get_cell_global_position(40)
	var expected := Vector3(-10.0, 0.0, -10.0)

	assert_almost_eq(pos.x, expected.x, 0.001, "Cell global X position should match expected value")
	assert_almost_eq(pos.y, expected.y, 0.001, "Cell global Y position should match expected value")
	assert_almost_eq(pos.z, expected.z, 0.001, "Cell global Z position should match expected value")
	
	
func test_get_cell_global_transform():
	var xform: Transform3D = interactive_grid_3d.get_cell_global_transform(0)
	assert_eq(
		xform.origin,
		interactive_grid_3d.get_cell_global_position(0),
		"Transform origin should match cell global position"
	)
	
	
func test_get_cell_index_from_global_position():
	interactive_grid_3d.center(Vector3(-10.0,0.0,-10.0))
	assert_eq(interactive_grid_3d.get_cell_index_from_global_position(Vector3(-10.0,0.0,-10.0)), 40, "Cell index should match expected value")
	
	
func test_center_global_position():
	interactive_grid_3d.center(Vector3(-10.0,0.0,-10.0))
	assert_eq(interactive_grid_3d.global_position, Vector3(-10.0,0.0,-10.0), "Grid center global position should match the given position")
	
	
func test_grid_visible():
	assert_true(interactive_grid_3d.is_visible(), "InteractiveGrid3D should be visible")
	
	
func test_get_latest_selected():
	interactive_grid_3d.select_cell(0)
	interactive_grid_3d.select_cell(8)
	interactive_grid_3d.select_cell(72)
	interactive_grid_3d.select_cell(80)
	assert_eq(interactive_grid_3d.get_latest_selected(), 80, "The latest selected cell should be 80")
	
	
func test_get_neighbors():
	var neighbors : Array = [41, 39, 49, 31]
	assert_eq(interactive_grid_3d.get_neighbors(40), neighbors, "Cell 40 should have the correct neighboring cells")
	
	
func test_get_neighbors_corner():
	var neighbors : Array = [1, 9]
	assert_eq(interactive_grid_3d.get_neighbors(0), neighbors, "Cell 0 (corner) should have the correct neighboring cells")
	
	
func test_get_path():
	var path : PackedInt64Array = [0, 9, 10, 19, 28, 29, 30, 39, 40, 49]
	assert_eq(interactive_grid_3d.get_path(0, 49), path, "Path from cell 0 to cell 49 should match the expected sequence")
	
	
func test_get_selected_cells():
	interactive_grid_3d.select_cell(0)
	interactive_grid_3d.select_cell(8)
	interactive_grid_3d.select_cell(72)
	interactive_grid_3d.select_cell(80)
	var selected_cells : Array = [0, 8, 72, 80]
	assert_eq(interactive_grid_3d.get_selected_cells(), selected_cells, "Should return all currently selected cells")
	
	
func test_get_size():
	assert_eq(interactive_grid_3d.get_size(), 81, "Grid size should be 81")
	
	
func test_hide_distant_cells():
	interactive_grid_3d.hide_distant_cells(40, 3)
	var invisible_count = 0
	for cell in range(81):
		if not interactive_grid_3d.is_cell_visible(cell):
			invisible_count += 1
	assert_eq(invisible_count, 52, "52 cells should be hidden when hiding distant cells from cell 40 with radius 3")
	
	
func test_highlight_on_hover():
	for cell in range(81):
		var cell_global_position = interactive_grid_3d.get_cell_global_position(cell)
		interactive_grid_3d.highlight_on_hover(cell_global_position)
		assert_true(interactive_grid_3d.is_cell_hovered(cell), "Cell should be highlighted on hover")
		await wait_seconds(0.05)
		
		
func test_highlight_path():
	var path : PackedInt64Array = [0, 9, 10, 19, 28, 29, 30, 39, 40, 49]
	interactive_grid_3d.highlight_path(path)
	assert_same(Color("90ee90"), interactive_grid_3d.get_cell_color(30), "Cell 40 color should match the assigned value Color(0, 1, 1)")
	
	
func test_is_cell_accessible():
	interactive_grid_3d.center(Vector3(0.0,0.0,-10.0))
	assert_false(interactive_grid_3d.is_cell_accessible(40), "Cell 40 should not be accessible after centering the grid at (0, 0, -10)")
	
	
func test_is_cell_hovered():
	interactive_grid_3d.highlight_on_hover(Vector3(0.0,0.0,0.0))
	assert_true(interactive_grid_3d.is_cell_hovered(40), "Cell 40 should be marked as hovered when highlighted at position (0, 0, 0)")
	
	
func test_is_reachable():
	interactive_grid_3d.center(Vector3(0.0,0.0,-10.0))
	interactive_grid_3d.compute_unreachable_cells(80)
	assert_false(interactive_grid_3d.is_cell_reachable(0), "Cell 0 should not be reachable after computing unreachable cells from cell 80")
	
	
func test_is_cell_selected():
	assert_false(interactive_grid_3d.is_cell_selected(0), "Cell 0 should not be selected initially")
	
	
func test_is_cell_visible():
	assert_true(interactive_grid_3d.is_cell_visible(0), "Cell 0 should be visible")
	
	
func test_is_created():
	assert_true(interactive_grid_3d.is_created(), "Grid should be created")
	
	
func test_is_hover_enabled():
	assert_true(interactive_grid_3d.is_hover_enabled(), "Hover functionality should be enabled")
	
	
func test_reset_cells_state(): #TODO
	pass
	
	
func test_select_cell():
	interactive_grid_3d.select_cell(0)
	assert_true(interactive_grid_3d.is_cell_selected(0), "Cell 0 should be selected after calling select_cell")
	
	
func test_set_cell_accesible():
	interactive_grid_3d.center(Vector3(0.0,0.0,-10.0))
	interactive_grid_3d.set_cell_accessible(40, true)
	assert_true(interactive_grid_3d.is_cell_accessible(40), "Cell 40 should be accessible after calling set_cell_accessible")
	
	
func test_set_cell_color():
	interactive_grid_3d.set_cell_color(40, Color(0.0, 1.0, 1.0))
	assert_same(Color(0.0, 1.0, 1.0), interactive_grid_3d.get_cell_color(40), "Cell 40 color should match the assigned value Color(0, 1, 1)")
	
	
func test_set_cell_reachable():
	interactive_grid_3d.center(Vector3(0.0,0.0,-10.0))
	interactive_grid_3d.compute_unreachable_cells(80)
	interactive_grid_3d.set_cell_reachable(0, true)
	assert_true(interactive_grid_3d.is_cell_reachable(0), "Cell 0 should be reachable")
	
	
func test_set_hover_enabled():
	interactive_grid_3d.set_hover_enabled(false)
	interactive_grid_3d.highlight_on_hover(Vector3(0.0,0.0,0.0))
	assert_false(interactive_grid_3d.is_cell_hovered(40), "Cell 40 should not be hovered when hover is disabled")
	
	
func test_update_custom_data(): # TODO
	pass


func test_set_obstacles_collision_enabled():
	interactive_grid_3d.set_obstacles_collision_enabled(false)
	assert_false(interactive_grid_3d.get_obstacles_collision_enabled(), "obstacles_enabled should be disabled")
