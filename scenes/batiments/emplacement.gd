extends "res://scenes/batiments/batiment_base.gd"
class_name Emplacement

const COULEUR_FOND_TENTE      := Color(0.35, 0.70, 0.35, 0.85)
const COULEUR_CONTOUR_TENTE   := Color(0.10, 0.45, 0.10, 1.0)
const LABEL_TENTE             := "TENTE"

const COULEUR_FOND_CARAVANE     := Color(0.85, 0.75, 0.40, 0.85)
const COULEUR_CONTOUR_CARAVANE  := Color(0.60, 0.45, 0.10, 1.0)
const LABEL_CARAVANE            := "CARAVANE"

const COULEUR_FOND_MOBIL_HOME     := Color(0.35, 0.55, 0.75, 0.85)
const COULEUR_CONTOUR_MOBIL_HOME  := Color(0.10, 0.30, 0.55, 1.0)
const LABEL_MOBIL_HOME            := "MOBIL-HOME"

const COULEUR_FOND_FALLBACK     := Color(0.55, 0.55, 0.55, 0.85)
const COULEUR_CONTOUR_FALLBACK  := Color(0.2, 0.2, 0.2, 1.0)
const LABEL_FALLBACK            := "EMPLACEMENT"


func _draw() -> void:
	if _data == null:
		return
	var cell: int = GridSystem.CELL_SIZE
	var rect_size := Vector2(_data.size.x * cell, _data.size.y * cell)

	var couleur_fond: Color
	var couleur_contour: Color
	var label: String

	match _data.type_id:
		"tente":
			couleur_fond    = COULEUR_FOND_TENTE
			couleur_contour = COULEUR_CONTOUR_TENTE
			label           = LABEL_TENTE
		"caravane":
			couleur_fond    = COULEUR_FOND_CARAVANE
			couleur_contour = COULEUR_CONTOUR_CARAVANE
			label           = LABEL_CARAVANE
		"mobil-home":
			couleur_fond    = COULEUR_FOND_MOBIL_HOME
			couleur_contour = COULEUR_CONTOUR_MOBIL_HOME
			label           = LABEL_MOBIL_HOME
		_:
			couleur_fond    = COULEUR_FOND_FALLBACK
			couleur_contour = COULEUR_CONTOUR_FALLBACK
			label           = LABEL_FALLBACK

	draw_rect(Rect2(Vector2.ZERO, rect_size), couleur_fond)
	draw_rect(Rect2(Vector2.ZERO, rect_size), couleur_contour, false, 2.0)

	var font := ThemeDB.fallback_font
	if font == null:
		return
	var font_size: int = 12
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos := Vector2(
		(rect_size.x - text_size.x) * 0.5,
		(rect_size.y + text_size.y) * 0.5
	)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
