extends Node

# UIManager — point d'entrée unique pour ouvrir/fermer les panneaux UI.
# Les panneaux sont des scènes chargées dynamiquement sur CanvasLayer (layer=2).
# Architecture : les panneaux lisent via GameData, modifient via EventBus — JAMAIS directement.

const SCENE_PATHS: Dictionary = {
	"campeur_fiche": "res://scenes/ui/campeur/campeur_fiche.tscn",
}

var _canvas_layer: CanvasLayer
var _panels: Dictionary = {}  # panel_name (String) → Control node


func _ready() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 2
	_canvas_layer.name = "UIPanelLayer"
	add_child(_canvas_layer)


func open(panel_name: String, data: Dictionary = {}) -> void:
	if _panels.has(panel_name):
		return  # Idempotent — panneau déjà ouvert, aucune action
	if not SCENE_PATHS.has(panel_name):
		push_warning("UIManager.open() — panneau inconnu : " + panel_name)
		return
	var scene := load(SCENE_PATHS[panel_name])
	if scene == null:
		push_error("UIManager.open() — scène introuvable : " + SCENE_PATHS[panel_name])
		return
	var panel: Node = scene.instantiate()
	panel.name = panel_name
	_canvas_layer.add_child(panel)
	_panels[panel_name] = panel
	if panel.has_method("initialize"):
		panel.initialize(data)


func close(panel_name: String) -> void:
	if not _panels.has(panel_name):
		return
	_panels[panel_name].queue_free()
	_panels.erase(panel_name)


func toggle(panel_name: String, data: Dictionary = {}) -> void:
	if _panels.has(panel_name):
		close(panel_name)
	else:
		open(panel_name, data)
