extends Node2D
class_name GridVisual

# Affichage visuel de la grille de placement.
# Statique — dessine les lignes une seule fois via _draw().
# Aucune logique métier ici : GridSystem est la source de vérité.

const GRID_COLS: int = 50        # 3200 / CELL_SIZE
const GRID_ROWS: int = 50
const BACKGROUND_COLOR: Color = Color(0.35, 0.50, 0.25, 1.0)  # vert herbe
const GRID_COLOR: Color = Color(0.0, 0.0, 0.0, 0.18)
const WORLD_SIZE: int = 3200


func _draw() -> void:
	var cell: int = GridSystem.CELL_SIZE

	# Fond de la carte
	draw_rect(Rect2(Vector2.ZERO, Vector2(WORLD_SIZE, WORLD_SIZE)), BACKGROUND_COLOR)

	# Lignes verticales
	for col in range(GRID_COLS + 1):
		var x: float = col * cell
		draw_line(Vector2(x, 0.0), Vector2(x, WORLD_SIZE), GRID_COLOR)

	# Lignes horizontales
	for row in range(GRID_ROWS + 1):
		var y: float = row * cell
		draw_line(Vector2(0.0, y), Vector2(WORLD_SIZE, y), GRID_COLOR)
