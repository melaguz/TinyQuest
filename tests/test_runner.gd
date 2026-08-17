extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const TILE_SIZE := 32.0

var _failures := 0
var _checks := 0


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	print("=== Grid Walk automated tests ===")
	await _test_step_has_intermediate_positions()
	await _test_four_directions_and_alignment()
	await _test_collision_blocks_cell()
	await _test_no_drift_after_many_steps()
	await _test_input_during_step_is_ignored()
	await _test_main_scene_and_tile_world()
	print("=== Result: %d checks, %d failures ===" % [_checks, _failures])
	quit(_failures)


func _test_step_has_intermediate_positions() -> void:
	var player := _new_player()
	await physics_frame
	var start := player.position
	var target := start + Vector2.RIGHT * TILE_SIZE
	_check(player.try_step(Vector2i.RIGHT), "smooth step starts")
	await physics_frame
	_check(player.position != start, "smooth step leaves its starting cell")
	_check(player.position != target, "smooth step has an intermediate visual position")
	_check(await _wait_for_step(player), "smooth step completes after intermediate frames")
	_check(player.position == target, "smooth step still finishes on exact target")
	player.queue_free()
	await process_frame


func _new_player(at: Vector2 = Vector2(80, 80)) -> GridPlayer:
	var player := PLAYER_SCENE.instantiate() as GridPlayer
	root.add_child(player)
	player.position = at
	return player


func _add_blocker(at: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	shape_node.shape = shape
	body.add_child(shape_node)
	body.position = at
	root.add_child(body)
	return body


func _test_four_directions_and_alignment() -> void:
	var player := _new_player()
	await physics_frame
	var start := player.position
	for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var before := player.position
		_check(player.try_step(direction), "step %s starts" % direction)
		_check(await _wait_for_step(player), "step %s completes" % direction)
		_check(player.position == before + Vector2(direction) * TILE_SIZE, "step %s moves exactly one tile" % direction)
		_check(player.is_grid_aligned(), "step %s ends aligned" % direction)
	_check(player.position == start, "opposite steps return to exact start")
	player.queue_free()
	await process_frame


func _test_collision_blocks_cell() -> void:
	var player := _new_player()
	var blocker := _add_blocker(player.position + Vector2.RIGHT * TILE_SIZE)
	await physics_frame
	var start := player.position
	_check(not player.try_step(Vector2i.RIGHT), "occupied cell rejects movement")
	await physics_frame
	_check(player.position == start, "blocked player position remains exact")
	player.queue_free()
	blocker.queue_free()
	await process_frame


func _test_no_drift_after_many_steps() -> void:
	var player := _new_player()
	await physics_frame
	var start := player.position
	for index in 10:
		_check(player.try_step(Vector2i.RIGHT), "repeated right step %d starts" % index)
		await _wait_for_step(player)
	for index in 10:
		_check(player.try_step(Vector2i.LEFT), "repeated left step %d starts" % index)
		await _wait_for_step(player)
	_check(player.position == start, "twenty steps cause zero positional drift")
	_check(player.is_grid_aligned(), "player remains grid-aligned after repeated steps")
	player.queue_free()
	await process_frame


func _test_input_during_step_is_ignored() -> void:
	var player := _new_player()
	await physics_frame
	var start := player.position
	_check(player.try_step(Vector2i.RIGHT), "first step starts")
	_check(not player.try_step(Vector2i.DOWN), "second input is ignored while moving")
	await _wait_for_step(player)
	_check(player.position == start + Vector2.RIGHT * TILE_SIZE, "ignored input adds no partial/extra step")
	player.queue_free()
	await process_frame


func _test_main_scene_and_tile_world() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var ground := main.get_node("World/Ground") as TileMapLayer
	var walls := main.get_node("World/Obstacles") as TileMapLayer
	_check(ground != null and ground.get_used_cells().size() == 280, "main scene builds 20x14 tile-based ground")
	_check(walls != null and not walls.get_used_cells().is_empty(), "main scene builds collidable wall tiles")
	_check(main.get_node_or_null("Tree") is StaticBody2D, "reusable Tree scene is instantiated")
	_check(main.get_node_or_null("Rock") is StaticBody2D, "reusable Rock scene is instantiated")
	var player := main.get_node("Player") as GridPlayer
	player.position = Vector2(48, 48)
	await physics_frame
	_check(not player.try_step(Vector2i.LEFT), "TileSet wall physics blocks a real map cell")
	player.position = Vector2(208, 176)
	await physics_frame
	_check(not player.try_step(Vector2i.RIGHT), "reusable Tree scene collision blocks movement")
	main.queue_free()
	await process_frame


func _wait_for_step(player: GridPlayer) -> bool:
	for _frame in 180:
		await physics_frame
		if not player.is_moving():
			return true
	return false


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
