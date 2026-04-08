extends Node2D

# World — scène principale du jeu Camping
# Logique métier dans les autoloads uniquement.

const CameraControllerScript := preload("res://scenes/world/camera_controller.gd")
const GridVisualScript := preload("res://scenes/world/grid_visual.gd")
const PlacementPreviewScript := preload("res://scenes/ui/construction/placement_preview.gd")
const TimeControllerScript := preload("res://scenes/ui/hud/time_controller.gd")
const SpeedHUDScript := preload("res://scenes/ui/hud/speed_hud.gd")
const DayNightOverlayScript := preload("res://scenes/world/day_night_overlay.gd")
const SettingsPanelScript := preload("res://scenes/ui/panels/settings_panel.gd")
const CampeurScene := preload("res://scenes/campeurs/campeur.tscn")
const IDGeneratorScript := preload("res://scripts/utils/id_generator.gd")
const ConstructionMenuScript := preload("res://scenes/ui/construction/construction_menu.gd")
const BatimentBaseScene := preload("res://scenes/batiments/batiment_base.tscn")
const MilestonePopupScript := preload("res://scenes/ui/overlays/milestone_popup.gd")

const BATIMENT_SCENES: Dictionary = {
	"accueil":    "res://scenes/batiments/accueil.tscn",
	"tente":      "res://scenes/batiments/emplacement.tscn",
	"caravane":   "res://scenes/batiments/emplacement.tscn",
	"mobil-home": "res://scenes/batiments/emplacement.tscn",
	"sanitaires": "res://scenes/batiments/sanitaires.tscn",
	"snack":      "res://scenes/batiments/snack.tscn",
	"piscine":    "res://scenes/batiments/piscine.tscn",
	"chemin":     "res://scenes/batiments/chemin.tscn",
}

@export var debug_spawn_campeur: bool = false
@export var debug_spawn_campeur_count: int = 2

const SPAWN_POSITIONS: Array[Vector2i] = [
	Vector2i(5, 5),
	Vector2i(35, 35),
	Vector2i(5, 35),
	Vector2i(35, 5),
]
const PRENOMS_TEST: Array[String] = ["Marcel", "Brigitte", "Kevin", "Sandrine"]

var _test_campeurs: Array = []  # Array[Campeur] — non typé pour éviter le problème de scope class_name
var _placement_active: bool = false
var _preview  # PlacementPreview — non typé pour éviter le conflit de scope class_name (cf. _test_campeur)
var _batiments_node: Node2D            # conteneur pour les bâtiments placés
var _chemin_drag_active: bool = false
var _chemin_last_drag_cell: Vector2i = Vector2i(-1, -1)
var _construction_menu  # ConstructionMenu — référence pour refresh budget
var _overlay_layer: CanvasLayer        # layer=3 pour les popups milestones


func _ready() -> void:
	_setup_camera()
	_setup_grid_visual()
	_setup_placement_preview()
	_setup_batiments_node()
	_setup_construction_menu()
	_setup_hud()
	_setup_settings_panel()
	_setup_overlay_layer()
	EventBus.subscribe("campeur.depart_avec_avis", _on_campeur_depart)
	EventBus.subscribe("campeur.arrive", _on_campeur_arrive)
	EventBus.subscribe("milestone.atteint", _on_milestone_atteint)
	if debug_spawn_campeur:
		_spawn_test_campeur()


func _exit_tree() -> void:
	EventBus.unsubscribe("campeur.depart_avec_avis", _on_campeur_depart)
	EventBus.unsubscribe("campeur.arrive", _on_campeur_arrive)
	EventBus.unsubscribe("milestone.atteint", _on_milestone_atteint)


func _unhandled_input(event: InputEvent) -> void:
	# Mode placement bâtiment
	if _placement_active:
		var type_id: String = _preview._type_id

		# Mode drag-to-trace pour les chemins
		if type_id == "chemin":
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					_chemin_drag_active = true
					_chemin_last_drag_cell = _preview.get_current_grid_pos() as Vector2i
					_confirm_placement()
				else:
					_chemin_drag_active = false
					_chemin_last_drag_cell = Vector2i(-1, -1)
				return
			elif event is InputEventMouseMotion and _chemin_drag_active:
				var cell: Vector2i = _preview.get_current_grid_pos()
				if cell != _chemin_last_drag_cell:
					_chemin_last_drag_cell = cell
					_confirm_placement()
				return

		# Placement standard (tous types, chemin inclus pour clic droit / Échap / rotation)
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
	if _test_campeurs.is_empty():
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
	_test_campeurs[0].move_to(world_pos)


func _spawn_test_campeur() -> void:
	var count := clampi(debug_spawn_campeur_count, 1, SPAWN_POSITIONS.size())
	for i in range(count):
		var data := CampeurData.new()
		data.campeur_id = "c_%03d" % (i + 1)
		data.prenom = PRENOMS_TEST[i]
		data.age = 35 + i * 7
		data.genre = "homme" if i % 2 == 0 else "femme"
		data.date_arrivee = SeasonManager.current_time
		data.date_depart_prevue = SeasonManager.current_time + float(3 + i) * SeasonManager.SECONDS_PER_DAY
		var campeur := CampeurScene.instantiate()
		add_child(campeur)
		campeur.initialize(data, GridSystem.grid_to_world(SPAWN_POSITIONS[i]))
		_test_campeurs.append(campeur)


func _setup_hud() -> void:
	var tc := TimeControllerScript.new()
	tc.name = "TimeController"
	add_child(tc)

	var hud := SpeedHUDScript.new()
	hud.name = "SpeedHUD"
	add_child(hud)

	var overlay := DayNightOverlayScript.new()
	overlay.name = "DayNightOverlay"
	add_child(overlay)


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
	_construction_menu = menu


func _on_placement_requested(type_id: String, size: Vector2i) -> void:
	if _placement_active:
		_cancel_placement()
	_placement_active = true
	_preview.activate(type_id, size)


func verifier_prerequis(type_id: String) -> bool:
	if type_id not in ["tente", "caravane", "mobil-home"]:
		return true
	for bat in GameData.batiments.values():
		if bat.type_id == "accueil":
			return true
	push_error("world._confirm_placement: un Accueil est requis avant de placer un emplacement")
	return false


func verifier_budget(type_id: String) -> bool:
	var cout: float = 0.0
	if GameData.cout_construction_par_type.has(type_id):
		cout = float(GameData.cout_construction_par_type[type_id])
	if GameData.argent < cout:
		push_error("world._confirm_placement: budget insuffisant — requis: %.0f€, disponible: %.0f€" % [cout, GameData.argent])
		return false
	return true


func _confirm_placement() -> void:
	if not _preview.is_valid_placement():
		return
	var grid_pos: Vector2i = _preview.get_current_grid_pos()
	var size: Vector2i = _preview.get_current_size()
	var type_id: String = _preview._type_id

	if not verifier_prerequis(type_id):
		return
	if not verifier_budget(type_id):
		return

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
	elif type_id == "piscine":
		var piscine_data := PiscineData.new()
		piscine_data.capacite_max = 20
		data = piscine_data
	elif type_id == "chemin":
		data = CheminData.new()
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

	# Exclure les chemins : un chemin n'est pas un "bâtiment" du point de vue du joueur
	var batiments_hors_chemin := GameData.batiments.values().filter(
		func(b: BatimentData) -> bool: return b.type_id != "chemin"
	)
	if batiments_hors_chemin.size() == 1 and GameData.verifier_milestone("premier_batiment"):
		EventBus.emit("milestone.atteint", {
			"entite_id": "world",
			"milestone_id": "premier_batiment",
			"timestamp": SeasonManager.current_time,
		})

	var cout: float = float(GameData.cout_construction_par_type.get(type_id, 0))
	GameData.argent -= cout
	if _construction_menu != null:
		_construction_menu.refresh_budget(GameData.argent)

	# Pour les chemins : rester en mode placement pour le drag continu
	if type_id != "chemin":
		_preview.deactivate()
		_placement_active = false


func _on_campeur_arrive(payload: Dictionary) -> void:
	if GameData.campeurs.size() == 1 and GameData.verifier_milestone("premier_campeur"):
		EventBus.emit("milestone.atteint", {
			"entite_id": "world",
			"milestone_id": "premier_campeur",
			"prenom": payload.get("prenom", ""),
			"timestamp": SeasonManager.current_time,
		})


func _on_campeur_depart(payload: Dictionary) -> void:
	var campeur_id: String = payload.get("entite_id", "")
	for campeur in _test_campeurs:
		if campeur != null and campeur.campeur_id == campeur_id:
			campeur.queue_free()
			_test_campeurs.erase(campeur)
			break

	# size == 1 : uniquement le tout premier avis. Si le premier avis est < 3, ce milestone
	# ne se déclenchera jamais — comportement intentionnel (on célèbre un succès, pas un échec).
	if GameData.avis.size() == 1 and payload.get("note", 0) >= 3:
		if GameData.verifier_milestone("premier_avis"):
			EventBus.emit("milestone.atteint", {
				"entite_id": "world",
				"milestone_id": "premier_avis",
				"note": payload.get("note", 0),
				"commentaire": payload.get("commentaire", ""),
				"timestamp": SeasonManager.current_time,
			})


func _cancel_placement() -> void:
	_chemin_drag_active = false
	_chemin_last_drag_cell = Vector2i(-1, -1)
	_preview.deactivate()
	_placement_active = false


func _setup_settings_panel() -> void:
	var panel := SettingsPanelScript.new()
	panel.name = "SettingsPanel"
	panel.visible = false
	add_child(panel)


func _setup_overlay_layer() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "OverlayLayer"
	_overlay_layer.layer = 3
	add_child(_overlay_layer)


func _on_milestone_atteint(payload: Dictionary) -> void:
	MilestonePopupScript.show_for(
		payload.get("milestone_id", ""),
		payload,
		_overlay_layer
	)
