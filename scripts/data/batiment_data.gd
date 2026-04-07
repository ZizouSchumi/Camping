class_name BatimentData extends Resource

@export var batiment_id: String = ""
@export var type_id: String = ""          # "accueil", "sanitaires", etc.
@export var grid_pos: Vector2i = Vector2i.ZERO
@export var size: Vector2i = Vector2i(1, 1)   # en cellules de grille (après rotation éventuelle)
@export var rotation_deg: int = 0         # 0 ou 90 — permute x/y de la taille
@export var capacite_max: int = 0         # capacité d'accueil, chargée depuis batiments_config.json
var campeurs_en_service: Array[String] = []  # état runtime — non persisté
