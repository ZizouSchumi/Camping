extends GutTest

# Tests unitaires pour le bâtiment Piscine (Story 3.6)
# Couvre PiscineData, héritage BatimentData, _draw, get_nearest

const PiscineScript := preload("res://scenes/batiments/piscine.gd")


func after_each() -> void:
	for key in GameData.batiments.keys():
		if key.begins_with("b_test_"):
			GameData.batiments.erase(key)


# AC #1 — PiscineData : valeurs par défaut
func test_piscine_data_defaults() -> void:
	var data := PiscineData.new()
	# capacite_max et campeurs_en_service sont dans BatimentData depuis S4.3
	assert_eq(data.capacite_max, 0, "capacite_max hérité de BatimentData — 0 par défaut (settée par world.gd)")
	assert_true(data.is_open, "is_open doit être true par défaut")
	assert_eq(data.campeurs_en_service, [], "campeurs_en_service hérité de BatimentData — vide par défaut")


# AC #1 — PiscineData hérite bien de BatimentData
func test_piscine_data_extends_batiment_data() -> void:
	var data := PiscineData.new()
	assert_true(data is BatimentData, "PiscineData doit hériter de BatimentData")


# AC #2 — _draw() ne crashe pas
func test_piscine_draw_ne_crash_pas() -> void:
	var piscine := PiscineScript.new()
	add_child(piscine)

	var data := PiscineData.new()
	data.batiment_id = "b_test_draw_piscine"
	data.type_id = "piscine"
	data.grid_pos = Vector2i(1, 1)
	data.size = Vector2i(5, 4)
	piscine.initialize(data)

	piscine.notification(CanvasItem.NOTIFICATION_DRAW)

	assert_not_null(piscine._data, "_data ne doit pas être null après initialize()")
	piscine.queue_free()


# AC #6 — get_nearest trouve une piscine placée
func test_get_nearest_trouve_piscine() -> void:
	var data := PiscineData.new()
	data.batiment_id = "b_test_piscine_nn"
	data.type_id = "piscine"
	data.grid_pos = Vector2i(5, 5)
	data.size = Vector2i(5, 4)
	GameData.batiments["b_test_piscine_nn"] = data

	var result := GridSystem.get_nearest(Vector2i(15, 15), "piscine")
	assert_eq(result, Vector2i(5, 5), "get_nearest doit retourner grid_pos de la piscine")


# AC #6 — get_nearest retourne Vector2i(-1,-1) si aucune piscine n'existe
func test_get_nearest_retourne_moins_un_si_absent() -> void:
	var result := GridSystem.get_nearest(Vector2i(5, 5), "piscine")
	assert_eq(result, Vector2i(-1, -1),
			"get_nearest doit retourner Vector2i(-1,-1) si aucune piscine n'existe")


# AC #1 — campeurs_en_service est mutable et isolé par instance (état runtime)
func test_piscine_campeurs_en_service_mutable() -> void:
	var data := PiscineData.new()
	data.campeurs_en_service.append("campeur_test")
	assert_eq(data.campeurs_en_service.size(), 1, "campeurs_en_service doit accepter des entrées")
	var data2 := PiscineData.new()
	assert_eq(data2.campeurs_en_service.size(), 0, "instances séparées ne partagent pas campeurs_en_service")
