extends GutTest

# Tests unitaires pour EventBus
# Nécessite GUT addon installé dans addons/gut/

var _event_bus: Node

func before_each() -> void:
	_event_bus = load("res://autoloads/event_bus.gd").new()
	add_child(_event_bus)

func after_each() -> void:
	_event_bus.queue_free()

func test_subscribe_et_emit_basic() -> void:
	var received_payload: Dictionary = {}
	var callback := func(payload: Dictionary) -> void:
		received_payload = payload

	_event_bus.subscribe("test.action", callback)
	_event_bus.emit("test.action", {"entite_id": "c_001", "value": 42})

	assert_eq(received_payload.get("entite_id"), "c_001", "Le payload doit contenir entite_id")
	assert_eq(received_payload.get("value"), 42, "Le payload doit contenir la valeur")

func test_emit_sans_subscriber_ne_crash_pas() -> void:
	# Ne doit pas lever d'erreur
	_event_bus.emit("evenement.inexistant", {})
	pass_test()

func test_unsubscribe_arrete_reception() -> void:
	var count := 0
	var callback := func(_payload: Dictionary) -> void:
		count += 1

	_event_bus.subscribe("test.compteur", callback)
	_event_bus.emit("test.compteur", {})
	assert_eq(count, 1, "Doit recevoir 1 événement après subscribe")

	_event_bus.unsubscribe("test.compteur", callback)
	_event_bus.emit("test.compteur", {})
	assert_eq(count, 1, "Ne doit plus recevoir après unsubscribe")

func test_multiple_subscribers_meme_evenement() -> void:
	var count := 0
	var cb1 := func(_p: Dictionary) -> void: count += 1
	var cb2 := func(_p: Dictionary) -> void: count += 1

	_event_bus.subscribe("test.multi", cb1)
	_event_bus.subscribe("test.multi", cb2)
	_event_bus.emit("test.multi", {})

	assert_eq(count, 2, "Les deux subscribers doivent recevoir l'événement")

func test_unsubscribe_inexistant_ne_crash_pas() -> void:
	var callback := func(_p: Dictionary) -> void: pass
	_event_bus.unsubscribe("evenement.inexistant", callback)
	pass_test()
