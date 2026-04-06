class_name ConstructionMenu extends VBoxContainer

# Catalogue minimal — les tailles sont en cellules de grille (CELL_SIZE = 64px)
# Ces définitions servent de référence pour toutes les stories E03.
const CATALOGUE: Dictionary = {
	"accueil":     { "label": "Accueil",     "size": Vector2i(3, 2) },
	"tente":       { "label": "Tente",       "size": Vector2i(2, 2) },
	"caravane":    { "label": "Caravane",    "size": Vector2i(3, 2) },
	"mobil-home":  { "label": "Mobil-Home",  "size": Vector2i(3, 3) },
	"sanitaires":  { "label": "Sanitaires",  "size": Vector2i(2, 3) },
	"snack":       { "label": "Snack",       "size": Vector2i(3, 3) },
	"piscine":     { "label": "Piscine",     "size": Vector2i(5, 4) },
	"chemin":      { "label": "Chemin",      "size": Vector2i(1, 1) },
}

signal placement_requested(type_id: String, size: Vector2i)

var _argent_label: Label


func _formater_argent(montant: float) -> String:
	var val := int(montant)
	if val >= 1000:
		return "💰 %d %03d€" % [val / 1000.0, val % 1000]
	return "💰 %d€" % val


func _ready() -> void:
	_argent_label = Label.new()
	_argent_label.text = _formater_argent(GameData.argent)
	add_child(_argent_label)

	var title := Label.new()
	title.text = "─ Construction ─"
	add_child(title)

	for type_id in CATALOGUE:
		var entry: Dictionary = CATALOGUE[type_id]
		var cout: int = GameData.cout_construction_par_type.get(type_id, 0)
		var btn := Button.new()
		btn.text = "%s (%d€)" % [entry["label"], cout]
		btn.set_meta("type_id", type_id)
		btn.disabled = GameData.argent < cout
		btn.pressed.connect(_on_button_pressed.bind(type_id))
		add_child(btn)


func refresh_budget(argent: float) -> void:
	if _argent_label != null:
		_argent_label.text = _formater_argent(argent)
	for child in get_children():
		if child is Button:
			var type_id: String = child.get_meta("type_id", "")
			if type_id != "":
				var cout: int = GameData.cout_construction_par_type.get(type_id, 0)
				child.disabled = argent < cout


func _on_button_pressed(type_id: String) -> void:
	placement_requested.emit(type_id, CATALOGUE[type_id]["size"])
