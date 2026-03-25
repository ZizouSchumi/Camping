extends Node

# SaveSystem — sérialisation/désérialisation JSON versionnée
# OBLIGATOIRE : ne jamais utiliser FileAccess directement ailleurs dans le projet
# Compatible Steam Cloud (fichiers texte JSON)

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 1


func save_game(slot: int) -> void:
	# Stub — implémenté en S1.6 (E01)
	push_warning("SaveSystem.save_game() — stub non implémenté (slot: %d)" % slot)


func load_game(slot: int) -> void:
	# Stub — implémenté en S1.6 (E01)
	push_warning("SaveSystem.load_game() — stub non implémenté (slot: %d)" % slot)


func serialize(resource: Resource) -> Dictionary:
	# Stub — implémenté en S1.6 (E01)
	return {}


func deserialize(data: Dictionary, type: GDScript) -> Resource:
	# Stub — implémenté en S1.6 (E01)
	return null
