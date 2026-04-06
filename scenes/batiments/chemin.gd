extends "res://scenes/batiments/batiment_base.gd"
class_name Chemin

const COULEUR_FOND    := Color(0.72, 0.65, 0.50, 0.90)  # gris-sable / gravier
const COULEUR_CONTOUR := Color(0.48, 0.42, 0.32, 1.0)   # brun-gris


func _draw() -> void:
	if _data == null:
		return
	var cell: int = GridSystem.CELL_SIZE
	var rect_size := Vector2(_data.size.x * cell, _data.size.y * cell)
	draw_rect(Rect2(Vector2.ZERO, rect_size), COULEUR_FOND)
	draw_rect(Rect2(Vector2.ZERO, rect_size), COULEUR_CONTOUR, false, 1.5)
	# Pas de label — 1 cellule = 64×64 px, trop petit pour du texte lisible
