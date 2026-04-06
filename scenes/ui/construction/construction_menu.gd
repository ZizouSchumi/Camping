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


func _ready() -> void:
	var title := Label.new()
	title.text = "─ Construction ─"
	add_child(title)

	for type_id in CATALOGUE:
		var entry: Dictionary = CATALOGUE[type_id]
		var btn := Button.new()
		btn.text = entry["label"]
		btn.pressed.connect(_on_button_pressed.bind(type_id))
		add_child(btn)


func _on_button_pressed(type_id: String) -> void:
	placement_requested.emit(type_id, CATALOGUE[type_id]["size"])
