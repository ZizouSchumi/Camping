extends GutTest

# Tests unitaires pour le bâtiment Accueil/Réception (Story 3.2)
# Nécessite GUT addon installé dans addons/gut/

const AccueilScript := preload("res://scenes/batiments/accueil.gd")


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func test_accueil_data_defaults() -> void:
	var data := AccueilData.new()
	# capacite_max et campeurs_en_service sont dans BatimentData depuis S4.3 (valeur 0 par défaut, settée par world.gd)
	assert_eq(data.capacite_max, 0, "capacite_max hérité de BatimentData — 0 par défaut (settée par world.gd)")
	assert_true(data.is_open, "is_open doit être true par défaut")
	assert_eq(data.total_checkins, 0, "total_checkins doit être 0 par défaut")
	assert_true(data.campeurs_en_service.is_empty(), "campeurs_en_service hérité de BatimentData — vide par défaut")


func test_accueil_data_extends_batiment_data() -> void:
	var data := AccueilData.new()
	assert_true(data is BatimentData, "AccueilData doit hériter de BatimentData")


func test_get_nearest_retourne_moins_un_si_vide() -> void:
	var sauvegarde: Dictionary = GameData.batiments.duplicate()
	GameData.batiments.clear()

	var result := GridSystem.get_nearest(Vector2i(10, 10), "accueil")
	assert_eq(result, Vector2i(-1, -1), "get_nearest doit retourner Vector2i(-1,-1) si aucun bâtiment")

	GameData.batiments.merge(sauvegarde, true)


func test_get_nearest_trouve_accueil_place() -> void:
	var data := AccueilData.new()
	data.batiment_id = "b_test_acc"
	data.type_id = "accueil"
	data.grid_pos = Vector2i(5, 5)
	data.size = Vector2i(3, 2)
	GameData.batiments["b_test_acc"] = data

	var result := GridSystem.get_nearest(Vector2i(10, 10), "accueil")
	assert_eq(result, Vector2i(5, 5), "get_nearest doit retourner grid_pos du bâtiment")

	GameData.batiments.erase("b_test_acc")


func test_get_nearest_ignore_autres_types() -> void:
	var d_sani := BatimentData.new()
	d_sani.batiment_id = "b_test_sani"
	d_sani.type_id = "sanitaires"
	d_sani.grid_pos = Vector2i(2, 2)
	d_sani.size = Vector2i(2, 3)
	GameData.batiments["b_test_sani"] = d_sani

	var d_acc := AccueilData.new()
	d_acc.batiment_id = "b_test_acc2"
	d_acc.type_id = "accueil"
	d_acc.grid_pos = Vector2i(15, 15)
	d_acc.size = Vector2i(3, 2)
	GameData.batiments["b_test_acc2"] = d_acc

	var result := GridSystem.get_nearest(Vector2i(5, 5), "accueil")
	assert_eq(result, Vector2i(15, 15), "get_nearest doit ignorer les autres types")

	GameData.batiments.erase("b_test_sani")
	GameData.batiments.erase("b_test_acc2")


func test_get_nearest_retourne_le_plus_proche() -> void:
	var d1 := AccueilData.new()
	d1.batiment_id = "b_test_proche"
	d1.type_id = "accueil"
	d1.grid_pos = Vector2i(5, 5)
	d1.size = Vector2i(3, 2)
	GameData.batiments["b_test_proche"] = d1

	var d2 := AccueilData.new()
	d2.batiment_id = "b_test_loin"
	d2.type_id = "accueil"
	d2.grid_pos = Vector2i(20, 20)
	d2.size = Vector2i(3, 2)
	GameData.batiments["b_test_loin"] = d2

	var result := GridSystem.get_nearest(Vector2i(6, 6), "accueil")
	assert_eq(result, Vector2i(5, 5), "get_nearest doit retourner le bâtiment le plus proche")

	GameData.batiments.erase("b_test_proche")
	GameData.batiments.erase("b_test_loin")


func test_accueil_draw_ne_crash_pas() -> void:
	var accueil := AccueilScript.new()
	add_child(accueil)

	var data := AccueilData.new()
	data.batiment_id = "b_draw_test"
	data.type_id = "accueil"
	data.grid_pos = Vector2i(1, 1)
	data.size = Vector2i(3, 2)
	accueil.initialize(data)

	await get_tree().process_frame

	assert_not_null(accueil._data, "_data ne doit pas être null après initialize()")

	accueil.queue_free()
