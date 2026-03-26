extends Node

# SaveSystem — sérialisation/désérialisation JSON versionnée
# OBLIGATOIRE : ne jamais utiliser FileAccess directement ailleurs dans le projet
# Compatible Steam Cloud (fichiers texte JSON)

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 1


func save_game(slot: int) -> void:
	_ensure_save_dir()
	var path: String = _slot_path(slot)

	var data: Dictionary = {
		"save_version": SAVE_VERSION,
		"time": {
			"current_time": SeasonManager.current_time,
			"current_day": SeasonManager.current_day,
			"current_hour": SeasonManager.current_hour,
			"time_scale": SeasonManager.time_scale,
			"speed_index": SeasonManager._speed_index,
			"paused": SeasonManager.paused,
		},
		"grid": {
			"cells": _serialize_grid(),
		},
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: impossible d'écrire dans %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	EventBus.emit("jeu.sauvegarde", {
		"entite_id": "world",
		"timestamp": SeasonManager.current_time,
		"slot": slot,
	})


func load_game(slot: int) -> void:
	var path: String = _slot_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("SaveSystem: fichier de sauvegarde introuvable — slot %d (%s)" % [slot, path])
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: impossible de lire %s" % path)
		return
	var raw: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_error("SaveSystem: format JSON invalide dans %s" % path)
		return

	var data: Dictionary = parsed
	if not data.has("save_version"):
		push_error("SaveSystem: save_version manquant dans %s" % path)
		return

	_restore_time(data.get("time", {}))
	_restore_grid(data.get("grid", {}).get("cells", {}))

	EventBus.emit("jeu.chargement", {
		"entite_id": "world",
		"timestamp": SeasonManager.current_time,
		"slot": slot,
	})


func serialize(resource: Resource) -> Dictionary:
	var data: Dictionary = {}
	for prop in resource.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_STORAGE:
			data[prop["name"]] = resource.get(prop["name"])
	return data


func deserialize(data: Dictionary, type: GDScript) -> Resource:
	var resource: Resource = type.new()
	for key in data:
		resource.set(key, data[key])
	return resource


# --- Helpers privés ---

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)


func _serialize_grid() -> Dictionary:
	var cells: Dictionary = {}
	for key in GridSystem._grid:
		var k: Vector2i = key
		cells["%d,%d" % [k.x, k.y]] = GridSystem._grid[key]
	return cells


func _restore_grid(cells: Dictionary) -> void:
	GridSystem._grid.clear()
	for key in cells:
		var parts: PackedStringArray = key.split(",")
		if parts.size() == 2:
			var pos := Vector2i(int(parts[0]), int(parts[1]))
			GridSystem._grid[pos] = cells[key]


func _restore_time(time_data: Dictionary) -> void:
	if time_data.is_empty():
		return
	SeasonManager.current_time = time_data.get("current_time", 0.0)
	SeasonManager.current_day = time_data.get("current_day", 1)
	SeasonManager.current_hour = time_data.get("current_hour", 8.0)
	SeasonManager.time_scale = time_data.get("time_scale", 1.0)
	SeasonManager._speed_index = time_data.get("speed_index", 0)
	SeasonManager.paused = time_data.get("paused", false)
