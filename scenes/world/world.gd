extends Node2D

# World — scène principale du jeu Camping
# Logique métier dans les autoloads uniquement.

const CameraControllerScript := preload("res://scenes/world/camera_controller.gd")
const GridVisualScript := preload("res://scenes/world/grid_visual.gd")
const PlacementPreviewScript := preload("res://scenes/ui/construction/placement_preview.gd")
const TimeControllerScript := preload("res://scenes/ui/hud/time_controller.gd")
const SpeedHUDScript := preload("res://scenes/ui/hud/speed_hud.gd")
const SettingsPanelScript := preload("res://scenes/ui/panels/settings_panel.gd")
const CampeurScene := preload("res://scenes/campeurs/campeur.tscn")
const IDGeneratorScript := preload("res://scripts/utils/id_generator.gd")
const ConstructionMenuScript := preload("res://scenes/ui/construction/construction_menu.gd")
const BatimentBaseScene := preload("res://scenes/batiments/batiment_base.tscn")

const BATIMENT_SCENES: Dictionary = {
	"accueil":    "res://scenes/batiments/accueil.tscn",
	"tente":      "res://scenes/batiments/emplacement.tscn",
	"caravane":   "res://scenes/batiments/emplacement.tscn",
	"mobil-home": "res://scenes/batiments/emplacement.tscn",
	"sanitaires": "res://scenes/batiments/sanitaires.tscn",
	"snack":      "res://scenes/batiments/snack.tscn",
}

@export var debug_spawn_campeur: bool = false

var _test_campeur = null  # Campeur — non typé pour éviter le problème de scope class_name
var _placement_active: bool = false
var _preview  # PlacementPreview — non typé pour éviter le conflit de scope class_name (cf. _test_campeur)
var _batiments_node: Node2D            # conteneur pour les bâtiments placés


func _ready() -> void:
	_setup_camera()
	_setup_grid_visual()
	_setup_placement_preview()
	_setup_batiments_node()
	_setup_construction_menu()
	_setup_hud()
	_setup_settings_panel()
	if debug_spawn_campeur:
		_spawn_test_campeur()


func _unhandled_input(event: InputEvent) -> void:
	# Mode placement bâtiment
	if _placement_active:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_confirm_placement()
				return
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_cancel_placement()
				return
		if event.is_action_pressed("ui_cancel"):
			_cancel_placement()
			return
		if event.is_action_pressed("rotate_building"):
			_preview.rotate_preview()
			return

	# Debug campeur (code existant inchangé)
	if not debug_spawn_campeur:
		return
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _test_campeur == null:
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
	_test_campeur.move_to(world_pos)


func _spawn_test_campeur() -> void:
	var data := CampeurData.new()
	data.campeur_id = IDGeneratorScript.generate_campeur_id()
	data.prenom = "Marcel"
	data.age = 45
	data.genre = "homme"
	data.date_arrivee = SeasonManager.current_time
	data.date_depart_prevue = SeasonManager.current_time + 7.0

	var campeur := CampeurScene.instantiate()
	add_child(campeur)
	campeur.initialize(data, GridSystem.grid_to_world(Vector2i(3, 3)))
	_test_campeur = campeur


func _setup_hud() -> void:
	var tc := TimeControllerScript.new()
	tc.name = "TimeController"
	add_child(tc)

	var hud := SpeedHUDScript.new()
	hud.name = "SpeedHUD"
	add_child(hud)


func _setup_camera() -> void:
	var cam := CameraControllerScript.new()
	cam.name = "CameraController"
	cam.position = Vector2(1600.0, 1600.0)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 3200
	cam.limit_bottom = 3200
	add_child(cam)


func _setup_grid_visual() -> void:
	# Fond ColorRect — garanti de s'afficher si la caméra fonctionne
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.35, 0.50, 0.25)
	bg.size = Vector2(3200.0, 3200.0)
	add_child(bg)

	var grid := GridVisualScript.new()
	grid.name = "GridVisual"
	add_child(grid)


func _setup_placement_preview() -> void:
	var preview := PlacementPreviewScript.new()
	preview.name = "PlacementPreview"
	preview.visible = false
	add_child(preview)
	_preview = preview


func _setup_batiments_node() -> void:
	_batiments_node = Node2D.new()
	_batiments_node.name = "Batiments"
	add_child(_batiments_node)


func _setup_construction_menu() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "ConstructionLayer"
	ui_layer.layer = 2
	add_child(ui_layer)

	var menu := ConstructionMenuScript.new()
	menu.name = "ConstructionMenu"
	ui_layer.add_child(menu)
	menu.placement_requested.connect(_on_placement_requested)


func _on_placement_requested(type_id: String, size: Vector2i) -> void:
	if _placement_active:
		_cancel_placement()
	_placement_active = true
	_preview.activate(type_id, size)


func _confirm_placement() -> void:
	if not _preview.is_valid_placement():
		return
	var grid_pos: Vector2i = _preview.get_current_grid_pos()
	var size: Vector2i = _preview.get_current_size()
	var type_id: String = _preview._type_id

	var data: BatimentData
	if type_id == "accueil":
		var accueil_data := AccueilData.new()
		accueil_data.capacite_max = 1
		data = accueil_data
	elif type_id in ["tente", "caravane", "mobil-home"]:
		var emplacement_data := EmplacementData.new()
		emplacement_data.capacite_max = 1
		data = emplacement_data
	elif type_id == "sanitaires":
		var sanitaires_data := SanitairesData.new()
		sanitaires_data.capacite_max = 4
		data = sanitaires_data
	elif type_id == "snack":
		var snack_data := SnackData.new()
		snack_data.capacite_max = 12
		data = snack_data
	else:
		data = BatimentData.new()
	data.batiment_id = IDGeneratorScript.generate_batiment_id()
	data.type_id = type_id
	data.grid_pos = grid_pos
	data.size = size

	GridSystem.place(data.batiment_id, grid_pos, size)
	GameData.batiments[data.batiment_id] = data

	var scene_to_use: PackedScene
	if BATIMENT_SCENES.has(type_id):
		scene_to_use = load(BATIMENT_SCENES[type_id])
	else:
		scene_to_use = BatimentBaseScene
	var batiment := scene_to_use.instantiate()
	if batiment == null:
		push_error("world._confirm_placement: instantiate() a retourné null pour type_id: " + type_id)
		GridSystem.remove(grid_pos, size)
		GameData.batiments.erase(data.batiment_id)
		return
	_batiments_node.add_child(batiment)
	batiment.initialize(data)

	EventBus.emit("batiment.construit", {
		"entite_id": data.batiment_id,
		"type_id": data.type_id,
		"grid_pos": data.grid_pos,
		"size": data.size,
		"timestamp": SeasonManager.current_time,
	})

	_preview.deactivate()
	_placement_active = false


func _cancel_placement() -> void:
	_preview.deactivate()
	_placement_active = false


func _setup_settings_panel() -> void:
	var panel := SettingsPanelScript.new()
	panel.name = "SettingsPanel"
	panel.visible = false
	add_child(panel)
