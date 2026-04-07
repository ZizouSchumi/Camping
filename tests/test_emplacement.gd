extends GutTest

# Tests unitaires pour le bâtiment Emplacement (Story 3.3)
# Couvre EmplacementData, héritage BatimentData, _draw, factory, get_nearest
# Nécessite GUT addon installé dans addons/gut/

const EmplacementScript := preload("res://scenes/batiments/emplacement.gd")


func before_each() -> void:
	pass


func after_each() -> void:
	for key in GameData.batiments.keys():
		if key.begins_with("b_test_"):
			GameData.batiments.erase(key)


# AC #1 — EmplacementData : valeurs par défaut
func test_emplacement_data_defaults() -> void:
	var data := EmplacementData.new()
	# capacite_max est dans BatimentData depuis S4.3 (settée à 1 par world.gd à la création)
	assert_eq(data.capacite_max, 0, "capacite_max hérité de BatimentData — 0 par défaut (settée par world.gd)")
	assert_eq(data.campeur_id, "", "campeur_id doit être vide par défaut")


# AC #1 — EmplacementData hérite bien de BatimentData
func test_emplacement_data_extends_batiment_data() -> void:
	var data := EmplacementData.new()
	assert_true(data is BatimentData, "EmplacementData doit hériter de BatimentData")


# AC #1 — campeur_id est bien un état runtime (non @export : vérifier qu'il est modifiable)
func test_campeur_id_modifiable_runtime() -> void:
	var data := EmplacementData.new()
	data.campeur_id = "c_042"
	assert_eq(data.campeur_id, "c_042", "campeur_id doit pouvoir être assigné à runtime")


# AC #2 — _draw() ne crashe pas pour "tente"
func test_emplacement_draw_ne_crash_pas_tente() -> void:
	var emp := EmplacementScript.new()
	add_child(emp)

	var data := EmplacementData.new()
	data.batiment_id = "b_test_draw_tente"
	data.type_id = "tente"
	data.grid_pos = Vector2i(1, 1)
	data.size = Vector2i(2, 2)
	emp.initialize(data)

	# Forcer la notification de dessin — garantit que _draw() est exécuté même en mode headless
	emp.notification(CanvasItem.NOTIFICATION_DRAW)

	assert_not_null(emp._data, "_data ne doit pas être null après initialize()")
	emp.queue_free()


# AC #2 — _draw() ne crashe pas pour "caravane"
func test_emplacement_draw_ne_crash_pas_caravane() -> void:
	var emp := EmplacementScript.new()
	add_child(emp)

	var data := EmplacementData.new()
	data.batiment_id = "b_test_draw_caravane"
	data.type_id = "caravane"
	data.grid_pos = Vector2i(1, 1)
	data.size = Vector2i(3, 2)
	emp.initialize(data)

	emp.notification(CanvasItem.NOTIFICATION_DRAW)

	assert_not_null(emp._data, "_data ne doit pas être null après initialize()")
	emp.queue_free()


# AC #2 — _draw() ne crashe pas pour "mobil-home"
func test_emplacement_draw_ne_crash_pas_mobil_home() -> void:
	var emp := EmplacementScript.new()
	add_child(emp)

	var data := EmplacementData.new()
	data.batiment_id = "b_test_draw_mobil"
	data.type_id = "mobil-home"
	data.grid_pos = Vector2i(1, 1)
	data.size = Vector2i(3, 3)
	emp.initialize(data)

	emp.notification(CanvasItem.NOTIFICATION_DRAW)

	assert_not_null(emp._data, "_data ne doit pas être null après initialize()")
	emp.queue_free()


# AC #1 — EmplacementData créable et stockable dans GameData pour "tente"
# Note: la factory world.gd._confirm_placement() est couverte par les tests d'intégration
func test_emplacement_data_stocke_dans_game_data_pour_tente() -> void:
	var data := EmplacementData.new()
	data.batiment_id = "b_test_factory_tente"
	data.type_id = "tente"
	data.grid_pos = Vector2i(2, 2)
	data.size = Vector2i(2, 2)
	GameData.batiments["b_test_factory_tente"] = data

	assert_true(GameData.batiments.has("b_test_factory_tente"), "GameData doit contenir la tente")
	assert_true(GameData.batiments["b_test_factory_tente"] is EmplacementData,
			"La valeur doit être un EmplacementData")


# AC #1 — EmplacementData créable et stockable dans GameData pour "caravane"
func test_emplacement_data_stocke_dans_game_data_pour_caravane() -> void:
	var data := EmplacementData.new()
	data.batiment_id = "b_test_factory_caravane"
	data.type_id = "caravane"
	data.grid_pos = Vector2i(3, 3)
	data.size = Vector2i(3, 2)
	GameData.batiments["b_test_factory_caravane"] = data

	assert_true(GameData.batiments.has("b_test_factory_caravane"), "GameData doit contenir la caravane")
	assert_true(GameData.batiments["b_test_factory_caravane"] is EmplacementData,
			"La valeur doit être un EmplacementData")


# AC #1 — EmplacementData créable et stockable dans GameData pour "mobil-home"
func test_emplacement_data_stocke_dans_game_data_pour_mobil_home() -> void:
	var data := EmplacementData.new()
	data.batiment_id = "b_test_factory_mobil"
	data.type_id = "mobil-home"
	data.grid_pos = Vector2i(4, 4)
	data.size = Vector2i(3, 3)
	GameData.batiments["b_test_factory_mobil"] = data

	assert_true(GameData.batiments.has("b_test_factory_mobil"), "GameData doit contenir le mobil-home")
	assert_true(GameData.batiments["b_test_factory_mobil"] is EmplacementData,
			"La valeur doit être un EmplacementData")


# AC #7 — get_nearest trouve une tente placée
func test_get_nearest_trouve_tente() -> void:
	var data := EmplacementData.new()
	data.batiment_id = "b_test_tente_nn"
	data.type_id = "tente"
	data.grid_pos = Vector2i(5, 5)
	data.size = Vector2i(2, 2)
	GameData.batiments["b_test_tente_nn"] = data

	var result := GridSystem.get_nearest(Vector2i(10, 10), "tente")
	assert_eq(result, Vector2i(5, 5), "get_nearest doit retourner grid_pos de la tente")


# AC #7 — get_nearest retourne Vector2i(-1,-1) si aucun bâtiment du type n'existe
# Critique pour E04 : NeedsSystem doit vérifier ce retour avant d'attribuer un emplacement
func test_get_nearest_retourne_vecteur_moins_un_si_type_absent() -> void:
	var result := GridSystem.get_nearest(Vector2i(5, 5), "type_inexistant_xyz")
	assert_eq(result, Vector2i(-1, -1),
			"get_nearest doit retourner Vector2i(-1,-1) si aucun bâtiment du type n'existe")


# AC #7 — get_nearest ignore les autres types quand on cherche "tente"
func test_get_nearest_ignore_caravane_quand_cherche_tente() -> void:
	var d_caravane := EmplacementData.new()
	d_caravane.batiment_id = "b_test_caravane_ignore"
	d_caravane.type_id = "caravane"
	d_caravane.grid_pos = Vector2i(2, 2)
	d_caravane.size = Vector2i(3, 2)
	GameData.batiments["b_test_caravane_ignore"] = d_caravane

	var d_tente := EmplacementData.new()
	d_tente.batiment_id = "b_test_tente_loin"
	d_tente.type_id = "tente"
	d_tente.grid_pos = Vector2i(15, 15)
	d_tente.size = Vector2i(2, 2)
	GameData.batiments["b_test_tente_loin"] = d_tente

	var result := GridSystem.get_nearest(Vector2i(3, 3), "tente")
	assert_eq(result, Vector2i(15, 15), "get_nearest doit ignorer la caravane et trouver la tente")
