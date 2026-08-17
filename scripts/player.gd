class_name GridPlayer
extends CharacterBody2D

## One grid cell in pixels. Keep this equal to the TileSet cell size.
@export_range(8.0, 128.0, 1.0) var tile_size: float = 32.0
## Travel speed in pixels per second. 192 px/s makes a step last 1/6 second.
@export_range(32.0, 1024.0, 1.0) var move_speed: float = 192.0

signal step_started(from: Vector2, to: Vector2)
signal step_completed(at: Vector2)

var _target_position: Vector2
var _moving := false


func _ready() -> void:
	position = snapped_to_grid(position)
	_target_position = position


func _physics_process(delta: float) -> void:
	if _moving:
		position = position.move_toward(_target_position, move_speed * delta)
		if position.is_equal_approx(_target_position):
			# Assigning the exact target prevents accumulated floating-point drift.
			position = _target_position
			_moving = false
			step_completed.emit(position)
		return

	var direction := _read_direction()
	if direction != Vector2i.ZERO:
		try_step(direction)


## Starts one whole-cell step. Returns false when busy or when physics blocks it.
func try_step(direction: Vector2i) -> bool:
	if _moving or direction == Vector2i.ZERO:
		return false

	# Force four-way movement even if this method is called by other gameplay code.
	if direction.x != 0:
		direction = Vector2i(signi(direction.x), 0)
	else:
		direction = Vector2i(0, signi(direction.y))

	var motion := Vector2(direction) * tile_size
	if test_move(global_transform, motion):
		return false

	_target_position = position + motion
	_moving = true
	step_started.emit(position, _target_position)
	return true


func is_moving() -> bool:
	return _moving


func is_grid_aligned() -> bool:
	return position.is_equal_approx(snapped_to_grid(position))


func snapped_to_grid(value: Vector2) -> Vector2:
	# TileMapLayer cells are centered at half a tile: 16, 48, 80, ...
	var half_tile := Vector2.ONE * tile_size * 0.5
	return ((value - half_tile) / tile_size).round() * tile_size + half_tile


func _read_direction() -> Vector2i:
	# Input is ignored while moving (handled by the early return above). Horizontal
	# priority also guarantees that simultaneously-held keys never create diagonals.
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		return Vector2i.LEFT
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		return Vector2i.RIGHT
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		return Vector2i.UP
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		return Vector2i.DOWN
	return Vector2i.ZERO

