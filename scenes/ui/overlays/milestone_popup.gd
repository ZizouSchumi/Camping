class_name MilestonePopup
extends Control

# milestone_popup.gd — Notification flottante pour les early wins (S4.7)
# Utiliser MilestonePopup.show_for() — ne pas instancier directement.

const DUREE_AFFICHAGE: float = 3.0
const DUREE_ANIMATION: float = 0.4

const TEXTES: Dictionary = {
	"premier_batiment": "🏗️ Premier bâtiment !\nLe camping prend forme.",
	"premier_campeur":  "🏕️ Premier campeur !\nBienvenue, {prenom} !",
	"premier_avis":     "⭐ Premier avis ! {note}/5\n{commentaire}",
}
# Clés de payload autorisées dans les templates — évite les substitutions accidentelles
# (ex: {timestamp} ou {milestone_id} ne doivent pas apparaître dans les textes)
const CLES_TEMPLATE: Array[String] = ["prenom", "note", "commentaire"]

var _label: Label


static func show_for(milestone_id: String, data: Dictionary, parent: CanvasLayer) -> void:
	var popup := preload("res://scenes/ui/overlays/milestone_popup.tscn").instantiate()
	parent.add_child(popup)
	popup._afficher(milestone_id, data)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_label.position = Vector2(-150.0, -120.0)
	_label.custom_minimum_size = Vector2(300.0, 80.0)
	_label.mouse_filter = MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_label.add_theme_stylebox_override("normal", style)
	add_child(_label)
	modulate.a = 0.0


func _afficher(milestone_id: String, data: Dictionary) -> void:
	var texte: String = TEXTES.get(milestone_id, "🎉 Milestone atteint !")
	for key: String in CLES_TEMPLATE:
		if data.has(key):
			var valeur := str(data[key]) if data[key] != "" else "—"
			texte = texte.replace("{" + key + "}", valeur)
	_label.text = texte

	var tween := create_tween()
	position.y += 30.0
	tween.tween_property(self, "modulate:a", 1.0, DUREE_ANIMATION)
	tween.parallel().tween_property(self, "position:y", position.y - 30.0, DUREE_ANIMATION)
	tween.tween_interval(DUREE_AFFICHAGE)
	tween.tween_property(self, "modulate:a", 0.0, DUREE_ANIMATION)
	tween.tween_callback(queue_free)
