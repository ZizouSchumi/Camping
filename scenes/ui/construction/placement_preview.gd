extends Node2D
class_name PlacementPreview

# Aperçu de placement — suit le curseur en snappant à la grille.
# Vert = placement valide, Rouge = placement invalide.
# Désactivé par défaut — le système de construction (E03) active ce nœud.

const COLOR_VALID: Color = Color(0.0, 1.0, 0.0, 0.35)
const COLOR_INVALID: Color = Color(1.0, 0.0, 0.0, 0.35)

@export var preview_size: Vector2i = Vector2i(1, 1)

var _is_valid: bool = false


func _process(_delta: float) -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var grid_pos: Vector2i = GridSystem.world_to_grid(mouse_world)
	position = GridSystem.grid_to_world(grid_pos)
	_is_valid = GridSystem.can_place("preview", grid_pos, preview_size)
	queue_redraw()


func _draw() -> void:
	var cell: int = GridSystem.CELL_SIZE
	var rect_size: Vector2 = Vector2(preview_size.x * cell, preview_size.y * cell)
	var color: Color = COLOR_VALID if _is_valid else COLOR_INVALID
	draw_rect(Rect2(Vector2.ZERO, rect_size), color)
