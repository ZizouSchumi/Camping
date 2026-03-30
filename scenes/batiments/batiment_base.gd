class_name BatimentBase extends Node2D

var _data: BatimentData = null


func initialize(data: BatimentData) -> void:
	_data = data
	position = GridSystem.grid_to_world(data.grid_pos)
	queue_redraw()


func _draw() -> void:
	if _data == null:
		return
	var cell: int = GridSystem.CELL_SIZE
	var rect_size := Vector2(_data.size.x * cell, _data.size.y * cell)
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.55, 0.55, 0.55, 0.85))
	# Contour
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.2, 0.2, 0.2, 1.0), false, 2.0)
	# TODO E15 : remplacer par sprites dédiés par type
