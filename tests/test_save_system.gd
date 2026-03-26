extends GutTest

# Tests unitaires pour SaveSystem
# Vérifie la sérialisation, désérialisation, save/load et gestion des erreurs.

const TEST_SLOT := 99  # slot dédié aux tests, ne jamais utiliser en prod

var _save: Node
var _season: Node


# Resource minimale pour tester serialize/deserialize
class TestResource:
	extends Resource
	@export var nom: String = ""
	@export var valeur: int = 0


func before_each() -> void:
	_save = load("res://autoloads/save_system.gd").new()
	add_child(_save)
	_season = load("res://autoloads/season_manager.gd").new()
	add_child(_season)


func after_each() -> void:
	# Nettoyer le fichier de test
	var path: String = "user://saves/save_%d.json" % TEST_SLOT
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_save.queue_free()
	_season.queue_free()


func test_serialize_resource() -> void:
	var res := TestResource.new()
	res.nom = "camping"
	res.valeur = 42
	var data: Dictionary = _save.serialize(res)
	assert_has(data, "nom", "serialize() doit inclure la propriété 'nom'")
	assert_has(data, "valeur", "serialize() doit inclure la propriété 'valeur'")


func test_deserialize_restaure_valeurs() -> void:
	var data: Dictionary = {"nom": "test", "valeur": 7}
	var res: Resource = _save.deserialize(data, TestResource)
	assert_not_null(res, "deserialize() doit retourner une Resource")
	assert_eq(res.get("nom"), "test", "nom doit être restauré")
	assert_eq(res.get("valeur"), 7, "valeur doit être restaurée")


func test_serialize_deserialize_roundtrip() -> void:
	var original := TestResource.new()
	original.nom = "argelès"
	original.valeur = 100
	var data: Dictionary = _save.serialize(original)
	var restored: Resource = _save.deserialize(data, TestResource)
	assert_eq(restored.get("nom"), original.nom, "nom doit survivre le roundtrip")
	assert_eq(restored.get("valeur"), original.valeur, "valeur doit survivre le roundtrip")


func test_save_cree_fichier() -> void:
	_save.save_game(TEST_SLOT)
	var path: String = "user://saves/save_%d.json" % TEST_SLOT
	assert_true(FileAccess.file_exists(path), "save_game() doit créer le fichier JSON")


func test_load_slot_inexistant_ne_crash_pas() -> void:
	# Doit push_error() mais ne pas crasher
	_save.load_game(9999)
	assert_true(true, "load_game() sur slot inexistant ne doit pas crasher")


func test_save_load_roundtrip_time() -> void:
	# Configurer un état connu dans SeasonManager
	SeasonManager.current_time = 300.0
	SeasonManager.current_day = 2
	SeasonManager.time_scale = 4.0

	_save.save_game(TEST_SLOT)

	# Réinitialiser SeasonManager
	SeasonManager.current_time = 0.0
	SeasonManager.current_day = 1
	SeasonManager.time_scale = 1.0

	_save.load_game(TEST_SLOT)

	assert_almost_eq(SeasonManager.current_time, 300.0, 0.001, "current_time doit être restauré")
	assert_eq(SeasonManager.current_day, 2, "current_day doit être restauré")
	assert_almost_eq(SeasonManager.time_scale, 4.0, 0.001, "time_scale doit être restauré")
