class_name PlacementPreview extends Node2D

# Aperçu de placement — suit le curseur en snappant à la grille.
# Vert = placement valide, Rouge = placement invalide.
# Désactivé par défaut — le système de construction (E03) active ce nœud.

const COLOR_VALID: Color = Color(0.0, 1.0, 0.0, 0.35)
const COLOR_INVALID: Color = Color(1.0, 0.0, 0.0, 0.35)

@export var preview_size: Vector2i = Vector2i(1, 1)

var _is_valid: bool = false
var _active: bool = false
var _base_size: Vector2i = Vector2i(1, 1)
var _type_id: String = ""


func activate(type_id: String, base_size: Vector2i) -> void:
	_type_id = type_id
	_base_size = base_size
	preview_size = base_size
	_active = true
	visible = true


func deactivate() -> void:
	visible = false
	_active = false
	_type_id = ""


func rotate_preview() -> void:
	if not _active:
		return
	preview_size = Vector2i(preview_size.y, preview_size.x)


func is_valid_placement() -> bool:
	return _is_valid


func get_current_grid_pos() -> Vector2i:
	return GridSystem.world_to_grid(get_global_mouse_position())


func get_current_size() -> Vector2i:
	return preview_size


func _process(_delta: float) -> void:
	if not _active:
		return
	var grid_pos: Vector2i = GridSystem.world_to_grid(get_global_mouse_position())
	position = GridSystem.grid_to_world(grid_pos)
	_is_valid = GridSystem.can_place("preview", grid_pos, preview_size)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var cell: int = GridSystem.CELL_SIZE
	var rect_size: Vector2 = Vector2(preview_size.x * cell, preview_size.y * cell)
	var color: Color = COLOR_VALID if _is_valid else COLOR_INVALID
	draw_rect(Rect2(Vector2.ZERO, rect_size), color)
