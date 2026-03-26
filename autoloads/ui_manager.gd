extends Node

# UIManager — point d'entrée unique pour ouvrir/fermer les panneaux UI
# Les panneaux UI sont des scènes chargées dynamiquement
# Règle : les scènes UI sont chargées dynamiquement par UIManager uniquement


func open(panel_name: String, _data: Dictionary = {}) -> void:
	push_warning("UIManager.open() — stub non implémenté (panel: %s)" % panel_name)


func close(panel_name: String) -> void:
	push_warning("UIManager.close() — stub non implémenté (panel: %s)" % panel_name)


func toggle(panel_name: String) -> void:
	push_warning("UIManager.toggle() — stub non implémenté (panel: %s)" % panel_name)
