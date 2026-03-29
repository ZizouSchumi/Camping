extends GutTest

# tests/test_emote_display.gd
# Tests unitaires pour EmoteDisplay (S2.8)

const EmoteDisplayScript := preload("res://scenes/campeurs/emote_display.gd")

var _emote: EmoteDisplayScript


func before_each() -> void:
	_emote = EmoteDisplayScript.new()
	add_child(_emote)
	await get_tree().process_frame


func after_each() -> void:
	if is_instance_valid(_emote):
		_emote.queue_free()
	await get_tree().process_frame


func test_label_invisible_par_defaut() -> void:
	assert_false(_emote._label.visible, "Le label est invisible par défaut après _ready()")


func test_show_emote_visible() -> void:
	_emote.show_emote("🍽️")
	assert_true(_emote._label.visible, "Le label est visible après show_emote()")
	assert_eq(_emote._label.text, "🍽️", "Le texte du label correspond à l'emote")


func test_hide_emote_invisible() -> void:
	_emote.show_emote("🍽️")
	_emote.hide_emote()
	assert_false(_emote._label.visible, "Le label est invisible après hide_emote()")


func test_timer_expire_cache_emote() -> void:
	_emote.show_emote("💧")
	_emote._timer = 0.0
	_emote._process(0.001)
	assert_false(_emote._label.visible, "Le label est masqué lorsque le timer expire")


func test_besoin_critique_bon_id_affiche() -> void:
	_emote.setup("c_test_emote")
	EventBus.emit("besoin.critique", {
		"entite_id": "c_test_emote",
		"besoin_id": "faim",
		"niveau": "primaire",
		"timestamp": 0.0,
	})
	assert_true(_emote._label.visible, "L'emote est visible pour le bon campeur_id")
	assert_eq(_emote._label.text, "🍽️", "L'emoji 'faim' correspond à 🍽️")


func test_besoin_critique_autre_id_ignore() -> void:
	_emote.setup("c_test_emote")
	EventBus.emit("besoin.critique", {
		"entite_id": "c_autre",
		"besoin_id": "faim",
		"niveau": "primaire",
		"timestamp": 0.0,
	})
	assert_false(_emote._label.visible, "L'emote reste invisible pour un autre campeur_id")
