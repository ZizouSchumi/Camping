extends Node

# GridSystem — logique de placement sur grille (source de vérité spatiale)
# TileMap = visuel uniquement / GridSystem = logique de jeu
# Règle : ne jamais utiliser TileMap pour la logique de placement — toujours GridSystem

const CELL_SIZE: int = 64  # pixels par cellule de grille
const MAP_CELLS: int = 50  # 3200 / 64 = 50 — taille de la map monde (50×50 cellules)

var _grid: Dictionary = {}  # Vector2i → entity_id String
var _astar: AStarGrid2D = AStarGrid2D.new()


func _ready() -> void:
	_init_astar()


func _init_astar() -> void:
	_astar.region = Rect2i(Vector2i.ZERO, Vector2i(MAP_CELLS, MAP_CELLS))
	_astar.cell_size = Vector2i(CELL_SIZE, CELL_SIZE)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not _astar.is_in_boundsv(from) or not _astar.is_in_boundsv(to):
		return []
	if _astar.is_point_solid(to):
		return []
	var packed := _astar.get_id_path(from, to)
	var result: Array[Vector2i] = []
	for p: Vector2i in packed:
		result.append(p)
	return result


func can_place(_entity_id: String, pos: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var cell := pos + Vector2i(x, y)
			if not _astar.is_in_boundsv(cell):
				return false
			if _grid.has(cell):
				return false
	return true


func place(entity_id: String, pos: Vector2i, size: Vector2i) -> void:
	for x in range(size.x):
		for y in range(size.y):
			var cell := pos + Vector2i(x, y)
			_grid[cell] = entity_id
			if _astar.is_in_boundsv(cell):
				_astar.set_point_solid(cell, true)


func get_entity_at(pos: Vector2i) -> String:
	if not _grid.has(pos):
		return ""
	return _grid[pos]


func get_nearest(pos: Vector2i, type: String) -> Vector2i:
	var meilleur_pos := Vector2i(-1, -1)
	var meilleure_dist: int = 9999999
	for batiment_id in GameData.batiments:
		var data: BatimentData = GameData.batiments[batiment_id]
		if data.type_id == type:
			var cx: int = data.grid_pos.x + int(data.size.x * 0.5)
			var cy: int = data.grid_pos.y + int(data.size.y * 0.5)
			var dist: int = absi(cx - pos.x) + absi(cy - pos.y)
			if dist < meilleure_dist:
				meilleure_dist = dist
				meilleur_pos = data.grid_pos
	return meilleur_pos


func remove(pos: Vector2i, size: Vector2i) -> void:
	for x in range(size.x):
		for y in range(size.y):
			var cell := pos + Vector2i(x, y)
			_grid.erase(cell)
			if _astar.is_in_boundsv(cell):
				_astar.set_point_solid(cell, false)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / CELL_SIZE), floori(world_pos.y / CELL_SIZE))


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)
