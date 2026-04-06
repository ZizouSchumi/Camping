class_name PiscineData extends BatimentData

@export var capacite_max: int = 20
@export var is_open: bool = true
var campeurs_en_service: Array[String] = []  # état runtime — non persisté
