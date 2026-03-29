class_name EmoteDisplay extends Node2D

# scenes/campeurs/emote_display.gd
# Nœud fils de Campeur — affiche une bulle émotive flottante lors d'un besoin critique.
# Appeler setup(campeur_id) depuis campeur.gd après l'initialisation.

const EMOTE_DURATION: float = 4.0
const EMOTE_OFFSET: Vector2 = Vector2(0.0, -44.0)
const EMOTES: Dictionary = {
	"faim":           "🍽️",
	"soif":           "💧",
	"sommeil":        "😴",
	"hygiene":        "🚿",
	"energie":        "⚡",
	"social":         "💬",
	"divertissement": "🎯",
}

var _campeur_id: String = ""
var _label: Label
var _timer: float = 0.0


func _ready() -> void:
	_label = Label.new()
	_label.position = EMOTE_OFFSET
	_label.visible = false
	_label.add_theme_font_size_override("font_size", 14)
	add_child(_label)


func setup(campeur_id: String) -> void:
	if campeur_id == "" or _campeur_id != "":
		return
	_campeur_id = campeur_id
	EventBus.subscribe("besoin.critique", _on_besoin_critique)


func _exit_tree() -> void:
	if _campeur_id == "":
		return
	EventBus.unsubscribe("besoin.critique", _on_besoin_critique)


func show_emote(text: String) -> void:
	_label.text = text
	_label.visible = true
	_timer = EMOTE_DURATION


func hide_emote() -> void:
	_label.visible = false
	_timer = 0.0


func _on_besoin_critique(payload: Dictionary) -> void:
	if payload.get("entite_id", "") != _campeur_id:
		return
	var besoin_id: String = payload.get("besoin_id", "")
	show_emote(EMOTES.get(besoin_id, "❓"))


func _process(delta: float) -> void:
	if not _label.visible:
		return
	_timer -= delta
	if _timer <= 0.0:
		hide_emote()
