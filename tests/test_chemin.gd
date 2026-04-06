extends GutTest

# Tests unitaires pour le bâtiment Chemin (Story 3.7)
# Couvre CheminData, héritage BatimentData, _draw, GridSystem.can_place

const CheminScript := preload("res://scenes/batiments/chemin.gd")


func after_each() -> void:
	for key in GameData.batiments.keys():
		if key.begins_with("b_test_"):
			GameData.batiments.erase(key)


# AC #1 — CheminData hérite de BatimentData
func test_chemin_data_extends_batiment_data() -> void:
	var data := CheminData.new()
	assert_true(data is BatimentData, "CheminData doit hériter de BatimentData")


# AC #1 — les champs factory (type_id, grid_pos, batiment_id) sont assignables
func test_chemin_data_factory_fields_assignables() -> void:
	var data := CheminData.new()
	data.type_id = "chemin"
	data.grid_pos = Vector2i(5, 3)
	data.batiment_id = "b_test_chemin_factory"
	assert_eq(data.type_id, "chemin", "type_id doit être assignable")
	assert_eq(data.grid_pos, Vector2i(5, 3), "grid_pos doit être assignable")
	assert_eq(data.batiment_id, "b_test_chemin_factory", "batiment_id doit être assignable")


# AC #1 — type_id vide par défaut (assigné par factory world.gd)
func test_chemin_data_type_id_vide_par_defaut() -> void:
	var data := CheminData.new()
	assert_eq(data.type_id, "", "type_id doit être vide avant assignation factory")


# AC #2 — _draw() ne crashe pas
func test_chemin_draw_ne_crash_pas() -> void:
	var chemin := CheminScript.new()
	add_child(chemin)

	var data := CheminData.new()
	data.batiment_id = "b_test_draw_chemin"
	data.type_id = "chemin"
	data.grid_pos = Vector2i(1, 1)
	data.size = Vector2i(1, 1)
	chemin.initialize(data)

	chemin.notification(CanvasItem.NOTIFICATION_DRAW)

	assert_not_null(chemin._data, "_data ne doit pas être null après initialize()")
	chemin.queue_free()


# AC #6 — GridSystem accepte un chemin sur case libre
func test_grid_can_place_chemin_case_libre() -> void:
	assert_true(
		GridSystem.can_place("b_test_chemin_a", Vector2i(20, 20), Vector2i(1, 1)),
		"can_place doit accepter un chemin sur case libre"
	)


# AC #6 — GridSystem refuse placement sur case déjà occupée (anti-doublon drag)
func test_grid_refuse_placement_case_occupee() -> void:
	GridSystem.place("b_test_chemin_a", Vector2i(21, 21), Vector2i(1, 1))
	assert_false(
		GridSystem.can_place("b_test_chemin_b", Vector2i(21, 21), Vector2i(1, 1)),
		"can_place doit refuser une case déjà occupée"
	)
	GridSystem.remove(Vector2i(21, 21), Vector2i(1, 1))
