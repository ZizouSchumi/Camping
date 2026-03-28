extends GutTest

# Tests unitaires pour le pathfinding A* de GridSystem (Story 2.4)
# AC7 : couvre find_path sans obstacle, avec obstacle, destination solide, hors limites, même cellule

var _grid: Node
var _placed_cells: Array[Vector2i] = []


func before_each() -> void:
	_grid = load("res://autoloads/grid_system.gd").new()
	add_child(_grid)
	_placed_cells = []


func after_each() -> void:
	for cell in _placed_cells:
		_grid.remove(cell, Vector2i(1, 1))
	_placed_cells = []
	_grid.queue_free()


func _place_obstacle(cell: Vector2i) -> void:
	_grid.place("test_batiment_001", cell, Vector2i(1, 1))
	_placed_cells.append(cell)


# AC7a — chemin direct entre deux points adjacents
func test_find_path_direct_adjacent() -> void:
	var path: Array[Vector2i] = _grid.find_path(Vector2i(0, 0), Vector2i(0, 1))
	assert_false(path.is_empty(), "Chemin entre cellules adjacentes doit être non vide")
	assert_eq(path[0], Vector2i(0, 0), "Chemin doit commencer par la cellule de départ")
	assert_eq(path[path.size() - 1], Vector2i(0, 1), "Chemin doit terminer par la destination")


# AC7a — chemin entre deux points distants (3 cellules attendues)
func test_find_path_direct_distant() -> void:
	var path: Array[Vector2i] = _grid.find_path(Vector2i(0, 0), Vector2i(0, 2))
	assert_false(path.is_empty(), "Chemin entre points distants doit être non vide")
	assert_eq(path.size(), 3, "Chemin de (0,0) à (0,2) doit avoir 3 cellules")
	assert_eq(path[0], Vector2i(0, 0), "Chemin commence en (0,0)")
	assert_eq(path[2], Vector2i(0, 2), "Chemin finit en (0,2)")


# AC7b — chemin contourne un obstacle
func test_find_path_contourne_obstacle() -> void:
	# Layout :
	# (0,0) -- obstacle(1,0) -- (2,0)
	#   |                          |
	# (0,1) -------------------- (2,1)
	_place_obstacle(Vector2i(1, 0))
	var path: Array[Vector2i] = _grid.find_path(Vector2i(0, 0), Vector2i(2, 0))
	assert_false(path.is_empty(), "Chemin de contournement doit exister")
	assert_false(path.has(Vector2i(1, 0)), "Chemin ne doit pas traverser l'obstacle en (1,0)")


# AC7c — destination solide retourne tableau vide
func test_find_path_destination_solide() -> void:
	_place_obstacle(Vector2i(3, 3))
	var path: Array[Vector2i] = _grid.find_path(Vector2i(0, 0), Vector2i(3, 3))
	assert_true(path.is_empty(), "find_path vers cellule solide doit retourner []")


# AC7d — destination hors limites retourne tableau vide
func test_find_path_hors_limites() -> void:
	var path: Array[Vector2i] = _grid.find_path(Vector2i(0, 0), Vector2i(-1, -1))
	assert_true(path.is_empty(), "find_path hors limites doit retourner []")


# Cas limite — départ hors limites
func test_find_path_depart_hors_limites() -> void:
	var path: Array[Vector2i] = _grid.find_path(Vector2i(-1, -1), Vector2i(0, 0))
	assert_true(path.is_empty(), "find_path depuis hors limites doit retourner []")


# Cas limite — même cellule retourne [cellule]
func test_find_path_meme_cellule() -> void:
	var path: Array[Vector2i] = _grid.find_path(Vector2i(2, 2), Vector2i(2, 2))
	assert_eq(path.size(), 1, "find_path de même cellule doit retourner 1 élément")
	assert_eq(path[0], Vector2i(2, 2), "Élément unique doit être la cellule elle-même")


# Vérification que place() synchronise AStarGrid2D
func test_place_marque_cellule_solide() -> void:
	_place_obstacle(Vector2i(5, 5))
	var path_to_solid: Array[Vector2i] = _grid.find_path(Vector2i(0, 0), Vector2i(5, 5))
	assert_true(path_to_solid.is_empty(), "find_path vers cellule placée (solide) doit retourner []")


# AC6 — EventBus "campeur.destination_atteinte" émis à l'arrivée au dernier waypoint
func test_campeur_destination_atteinte_emis() -> void:
	var received := [false]
	var received_payload := [{}]
	var on_event := func(payload: Dictionary) -> void:
		received[0] = true
		received_payload[0] = payload
	EventBus.subscribe("campeur.destination_atteinte", on_event)

	var campeur_scene := load("res://scenes/campeurs/campeur.tscn")
	var campeur: Node = campeur_scene.instantiate()
	add_child(campeur)

	var data := CampeurData.new()
	data.campeur_id = "test_campeur_ac6"
	data.prenom = "TestAC6"
	data.age = 30
	data.genre = "homme"
	data.date_arrivee = 0.0
	data.date_depart_prevue = 100.0
	campeur.initialize(data, Vector2(32.0, 32.0))

	# Placer le campeur exactement au centre de la cellule (0,0) — distance = 0 <= ARRIVE_THRESHOLD
	var arrival_path: Array[Vector2i] = [Vector2i(0, 0)]
	campeur._path = arrival_path
	campeur._path_index = 0
	campeur.position = Vector2(32.0, 32.0)  # centre de (0,0) : grid_to_world + CELL_SIZE * 0.5

	campeur._physics_process(0.016)

	assert_true(received[0], "EventBus doit émettre 'campeur.destination_atteinte'")
	assert_eq(received_payload[0].get("entite_id", ""), "test_campeur_ac6", "payload.entite_id correct")
	assert_true(received_payload[0].has("timestamp"), "payload.timestamp présent")
	assert_true(received_payload[0].has("position"), "payload.position présent")

	EventBus.unsubscribe("campeur.destination_atteinte", on_event)
	campeur.queue_free()


# Vérification que remove() démarque AStarGrid2D
func test_remove_demarque_cellule() -> void:
	_place_obstacle(Vector2i(5, 5))
	# Retirer l'obstacle manuellement (sans passer par le helper pour contrôler)
	_grid.remove(Vector2i(5, 5), Vector2i(1, 1))
	_placed_cells.erase(Vector2i(5, 5))
	# Maintenant (5,5) ne doit plus être solide → chemin possible
	var path: Array[Vector2i] = _grid.find_path(Vector2i(0, 0), Vector2i(5, 5))
	assert_false(path.is_empty(), "Après remove(), cellule doit être accessible")
