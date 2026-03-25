extends Node

# GridSystem — logique de placement sur grille (source de vérité spatiale)
# TileMap = visuel uniquement / GridSystem = logique de jeu
# Règle : ne jamais utiliser TileMap pour la logique de placement — toujours GridSystem

var _grid: Dictionary = {}  # Vector2i → entity_id String


func can_place(entity_id: String, pos: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			if _grid.has(pos + Vector2i(x, y)):
				return false
	return true


func place(entity_id: String, pos: Vector2i, size: Vector2i) -> void:
	for x in range(size.x):
		for y in range(size.y):
			_grid[pos + Vector2i(x, y)] = entity_id


func get_entity_at(pos: Vector2i) -> String:
	if not _grid.has(pos):
		return ""
	return _grid[pos]


func get_nearest(pos: Vector2i, type: String) -> Vector2i:
	# Stub — implémenté en E03
	return Vector2i(-1, -1)


func remove(pos: Vector2i, size: Vector2i) -> void:
	for x in range(size.x):
		for y in range(size.y):
			_grid.erase(pos + Vector2i(x, y))
