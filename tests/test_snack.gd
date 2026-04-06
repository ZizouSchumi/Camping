extends GutTest

# Tests unitaires pour le bâtiment Snack (Story 3.5)
# Couvre SnackData, héritage BatimentData, _draw, get_nearest

const SnackScript := preload("res://scenes/batiments/snack.gd")


func after_each() -> void:
	for key in GameData.batiments.keys():
		if key.begins_with("b_test_"):
			GameData.batiments.erase(key)


# AC #1 — SnackData : valeurs par défaut
func test_snack_data_defaults() -> void:
	var data := SnackData.new()
	assert_eq(data.capacite_max, 12, "capacite_max doit être 12 par défaut")
	assert_true(data.is_open, "is_open doit être true par défaut")
	assert_eq(data.campeurs_en_service, [], "campeurs_en_service doit être vide par défaut")


# AC #1 — SnackData hérite bien de BatimentData
func test_snack_data_extends_batiment_data() -> void:
	var data := SnackData.new()
	assert_true(data is BatimentData, "SnackData doit hériter de BatimentData")


# AC #2 — _draw() ne crashe pas
func test_snack_draw_ne_crash_pas() -> void:
	var snack := SnackScript.new()
	add_child(snack)

	var data := SnackData.new()
	data.batiment_id = "b_test_draw_snack"
	data.type_id = "snack"
	data.grid_pos = Vector2i(1, 1)
	data.size = Vector2i(3, 3)
	snack.initialize(data)

	snack.notification(CanvasItem.NOTIFICATION_DRAW)

	assert_not_null(snack._data, "_data ne doit pas être null après initialize()")
	snack.queue_free()


# AC #6 — get_nearest trouve un snack placé
func test_get_nearest_trouve_snack() -> void:
	var data := SnackData.new()
	data.batiment_id = "b_test_snack_nn"
	data.type_id = "snack"
	data.grid_pos = Vector2i(5, 5)
	data.size = Vector2i(3, 3)
	GameData.batiments["b_test_snack_nn"] = data

	var result := GridSystem.get_nearest(Vector2i(10, 10), "snack")
	assert_eq(result, Vector2i(5, 5), "get_nearest doit retourner grid_pos du snack")


# AC #6 — get_nearest retourne Vector2i(-1,-1) si aucun snack n'existe
func test_get_nearest_retourne_moins_un_si_absent() -> void:
	var result := GridSystem.get_nearest(Vector2i(5, 5), "snack")
	assert_eq(result, Vector2i(-1, -1),
			"get_nearest doit retourner Vector2i(-1,-1) si aucun snack n'existe")
