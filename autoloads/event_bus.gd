extends Node

# EventBus — bus d'événements global pour la communication inter-systèmes
# Utilisation : EventBus.emit("domaine.action", { "entite_id": ..., "timestamp": ... })
# Règle : pour communication GLOBALE uniquement (entre systèmes sans relation hiérarchique)

var _listeners: Dictionary = {}


func subscribe(event_name: String, callable: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	_listeners[event_name].append(callable)


func emit(event_name: String, payload: Dictionary = {}) -> void:
	if not _listeners.has(event_name):
		return
	for listener in _listeners[event_name]:
		listener.call(payload)


func unsubscribe(event_name: String, callable: Callable) -> void:
	if not _listeners.has(event_name):
		return
	_listeners[event_name].erase(callable)
