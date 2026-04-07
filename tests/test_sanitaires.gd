extends GutTest

# Tests unitaires pour le bâtiment Sanitaires (Story 3.4)
# Couvre SanitairesData, héritage BatimentData, _draw, get_nearest

const SanitairesScript := preload("res://scenes/batiments/sanitaires.gd")


func after_each() -> void:
	for key in GameData.batiments.keys():
		if key.begins_with("b_test_"):
			GameData.batiments.erase(key)


# AC #1 — SanitairesData : valeurs par défaut
func test_sanitaires_data_defaults() -> void:
	var data := SanitairesData.new()
	# capacite_max et campeurs_en_service sont dans BatimentData depuis S4.3
	assert_eq(data.capacite_max, 0, "capacite_max hérité de BatimentData — 0 par défaut (settée par world.gd)")
	assert_true(data.is_open, "is_open doit être true par défaut")
	assert_eq(data.campeurs_en_service, [], "campeurs_en_service hérité de BatimentData — vide par défaut")


# AC #1 — SanitairesData hérite bien de BatimentData
func test_sanitaires_data_extends_batiment_data() -> void:
	var data := SanitairesData.new()
	assert_true(data is BatimentData, "SanitairesData doit hériter de BatimentData")


# AC #2 — _draw() ne crashe pas
func test_sanitaires_draw_ne_crash_pas() -> void:
	var san := SanitairesScript.new()
	add_child(san)

	var data := SanitairesData.new()
	data.batiment_id = "b_test_draw_sanitaires"
	data.type_id = "sanitaires"
	data.grid_pos = Vector2i(1, 1)
	data.size = Vector2i(2, 3)
	san.initialize(data)

	# Forcer la notification de dessin — garantit que _draw() est exécuté même en mode headless
	san.notification(CanvasItem.NOTIFICATION_DRAW)

	assert_not_null(san._data, "_data ne doit pas être null après initialize()")
	san.queue_free()


# AC #6 — get_nearest trouve un sanitaires placé
func test_get_nearest_trouve_sanitaires() -> void:
	var data := SanitairesData.new()
	data.batiment_id = "b_test_san_nn"
	data.type_id = "sanitaires"
	data.grid_pos = Vector2i(5, 5)
	data.size = Vector2i(2, 3)
	GameData.batiments["b_test_san_nn"] = data

	var result := GridSystem.get_nearest(Vector2i(10, 10), "sanitaires")
	assert_eq(result, Vector2i(5, 5), "get_nearest doit retourner grid_pos du sanitaires")


# AC #6 — get_nearest retourne Vector2i(-1,-1) si aucun sanitaires n'existe
func test_get_nearest_retourne_moins_un_si_absent() -> void:
	var result := GridSystem.get_nearest(Vector2i(5, 5), "sanitaires")
	assert_eq(result, Vector2i(-1, -1),
			"get_nearest doit retourner Vector2i(-1,-1) si aucun sanitaires n'existe")
