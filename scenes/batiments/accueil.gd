extends "res://scenes/batiments/batiment_base.gd"
class_name Accueil

const COULEUR_FOND := Color(0.18, 0.48, 0.82, 0.85)
const COULEUR_CONTOUR := Color(0.05, 0.25, 0.55, 1.0)
const LABEL := "ACCUEIL"


func _draw() -> void:
	if _data == null:
		return
	var cell: int = GridSystem.CELL_SIZE
	var rect_size := Vector2(_data.size.x * cell, _data.size.y * cell)
	draw_rect(Rect2(Vector2.ZERO, rect_size), COULEUR_FOND)
	draw_rect(Rect2(Vector2.ZERO, rect_size), COULEUR_CONTOUR, false, 2.0)
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var font_size: int = 12
	var text_size := font.get_string_size(LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos := Vector2(
		(rect_size.x - text_size.x) * 0.5,
		(rect_size.y + text_size.y) * 0.5
	)
	draw_string(font, text_pos, LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
