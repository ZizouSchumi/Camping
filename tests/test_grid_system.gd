extends GutTest

# Tests unitaires pour GridSystem
# Nécessite GUT addon installé dans addons/gut/

var _grid: Node

func before_each() -> void:
	_grid = load("res://autoloads/grid_system.gd").new()
	add_child(_grid)

func after_each() -> void:
	_grid.queue_free()

func test_can_place_sur_case_vide() -> void:
	var result: bool = _grid.can_place("b_001", Vector2i(0, 0), Vector2i(1, 1))
	assert_true(result, "Doit pouvoir placer sur une case vide")

func test_can_place_retourne_false_si_occupe() -> void:
	_grid.place("b_001", Vector2i(0, 0), Vector2i(2, 2))
	var result: bool = _grid.can_place("b_002", Vector2i(0, 0), Vector2i(1, 1))
	assert_false(result, "Ne doit pas pouvoir placer sur une case occupée")

func test_can_place_overlap_partiel() -> void:
	_grid.place("b_001", Vector2i(0, 0), Vector2i(3, 3))
	var result: bool = _grid.can_place("b_002", Vector2i(2, 2), Vector2i(2, 2))
	assert_false(result, "Ne doit pas pouvoir placer en overlap partiel")

func test_place_et_get_entity_at() -> void:
	_grid.place("b_001", Vector2i(5, 5), Vector2i(2, 2))
	assert_eq(_grid.get_entity_at(Vector2i(5, 5)), "b_001", "Doit retrouver l'entité à (5,5)")
	assert_eq(_grid.get_entity_at(Vector2i(6, 6)), "b_001", "Doit retrouver l'entité à (6,6)")

func test_get_entity_at_case_vide_retourne_chaine_vide() -> void:
	var result: String = _grid.get_entity_at(Vector2i(99, 99))
	assert_eq(result, "", "Case vide doit retourner chaîne vide")

func test_remove_libere_cases() -> void:
	_grid.place("b_001", Vector2i(0, 0), Vector2i(2, 2))
	_grid.remove(Vector2i(0, 0), Vector2i(2, 2))

	assert_eq(_grid.get_entity_at(Vector2i(0, 0)), "", "Case (0,0) doit être libre après remove")
	assert_eq(_grid.get_entity_at(Vector2i(1, 1)), "", "Case (1,1) doit être libre après remove")

func test_can_place_apres_remove() -> void:
	_grid.place("b_001", Vector2i(0, 0), Vector2i(2, 2))
	_grid.remove(Vector2i(0, 0), Vector2i(2, 2))
	var result: bool = _grid.can_place("b_002", Vector2i(0, 0), Vector2i(2, 2))
	assert_true(result, "Doit pouvoir placer après remove")

func test_get_nearest_stub_retourne_moins_un() -> void:
	var result: Vector2i = _grid.get_nearest(Vector2i(0, 0), "batiment")
	assert_eq(result, Vector2i(-1, -1), "get_nearest stub doit retourner (-1,-1)")

func test_world_to_grid_origine() -> void:
	var result: Vector2i = _grid.world_to_grid(Vector2(0.0, 0.0))
	assert_eq(result, Vector2i(0, 0), "Origine monde doit donner cellule (0,0)")

func test_world_to_grid_snap() -> void:
	# CELL_SIZE = 64 → position (100, 100) → cellule (1, 1)
	var result: Vector2i = _grid.world_to_grid(Vector2(100.0, 100.0))
	assert_eq(result, Vector2i(1, 1), "Position (100,100) doit mapper à cellule (1,1)")

func test_grid_to_world() -> void:
	var result: Vector2 = _grid.grid_to_world(Vector2i(1, 1))
	assert_eq(result, Vector2(64.0, 64.0), "Cellule (1,1) doit mapper à position monde (64,64)")

func test_snap_aller_retour() -> void:
	# world_to_grid(grid_to_world(pos)) doit être idempotent
	var original: Vector2i = Vector2i(3, 7)
	var world: Vector2 = _grid.grid_to_world(original)
	var back: Vector2i = _grid.world_to_grid(world)
	assert_eq(back, original, "Aller-retour grid→world→grid doit être idempotent")
