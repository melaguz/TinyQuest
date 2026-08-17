class_name DemoWorld
extends Node2D

const MAP_SIZE := Vector2i(20, 14)
const FLOOR_SOURCE := 0
const WALL_SOURCE := 1
const TILE_COORDS := Vector2i.ZERO

@onready var ground: TileMapLayer = $Ground
@onready var obstacles: TileMapLayer = $Obstacles


func _ready() -> void:
	build_demo_map()


## Populates real TileMapLayer cells. In a larger game the same TileSet can be
## painted directly in the editor; this compact demo keeps its layout readable.
func build_demo_map() -> void:
	ground.clear()
	obstacles.clear()
	for y in MAP_SIZE.y:
		for x in MAP_SIZE.x:
			ground.set_cell(Vector2i(x, y), FLOOR_SOURCE, TILE_COORDS)
	for x in MAP_SIZE.x:
		_set_wall(Vector2i(x, 0))
		_set_wall(Vector2i(x, MAP_SIZE.y - 1))
	for y in range(1, MAP_SIZE.y - 1):
		_set_wall(Vector2i(0, y))
		_set_wall(Vector2i(MAP_SIZE.x - 1, y))
	for y in range(3, 11):
		if y != 7:
			_set_wall(Vector2i(5, y))
	for cell in [Vector2i(11, 3), Vector2i(12, 3), Vector2i(13, 3), Vector2i(13, 4)]:
		_set_wall(cell)


func _set_wall(cell: Vector2i) -> void:
	obstacles.set_cell(cell, WALL_SOURCE, TILE_COORDS)

