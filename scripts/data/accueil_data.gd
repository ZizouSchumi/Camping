class_name AccueilData extends BatimentData

@export var capacite_max: int = 1
var campeurs_en_service: Array[String] = []   # état runtime — non persisté
@export var is_open: bool = true
@export var total_checkins: int = 0
