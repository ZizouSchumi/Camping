extends Node

# GameData — registry global de toutes les Resources actives du jeu
# Source de vérité pour campeurs, bâtiments, staff en mémoire
# Les panneaux UI lisent via GameData, modifient via EventBus uniquement

var campeurs: Dictionary = {}       # campeur_id → CampeurData
var batiments: Dictionary = {}      # batiment_id → BatimentData
var staff_members: Dictionary = {}  # staff_id → StaffData
var affinites: Dictionary = {}      # "c_001|c_002" → AffiniteData

var argent: float = 10000.0
var cout_construction_par_type: Dictionary = {}


func get_affinite_key(id_a: String, id_b: String) -> String:
	# Trier pour garantir l'unicité peu importe l'ordre A↔B
	if id_a < id_b:
		return id_a + "|" + id_b
	return id_b + "|" + id_a


func _ready() -> void:
	_charger_couts_construction()


func _charger_couts_construction() -> void:
	var path := "res://assets/data/batiments_config.json"
	if not FileAccess.file_exists(path):
		push_error("GameData: batiments_config.json introuvable")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameData: impossible d'ouvrir batiments_config.json")
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_error("GameData: JSON invalide dans batiments_config.json")
		return
	var data: Dictionary = json.data
	if not data.has("batiments"):
		return
	for type_id in data["batiments"]:
		var entry: Dictionary = data["batiments"][type_id]
		if entry.has("cout_construction"):
			cout_construction_par_type[type_id] = entry["cout_construction"]
