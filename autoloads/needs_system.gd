extends Node

# NeedsSystem — boucle centralisée de mise à jour des besoins de TOUS les PNJ
# UNE seule boucle pour N campeurs (pas de boucle individuelle par campeur)
# Implémentation complète en E02

var _registered_campeurs: Array[String] = []


func _process(delta: float) -> void:
	# Stub — implémenté en E02 (S2.2)
	pass


func register_campeur(campeur_id: String) -> void:
	if campeur_id not in _registered_campeurs:
		_registered_campeurs.append(campeur_id)


func unregister_campeur(campeur_id: String) -> void:
	_registered_campeurs.erase(campeur_id)
