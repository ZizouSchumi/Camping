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

@export var debug_spawn_campeur: bool = false

var _test_campeur = null  # Campeur — non typé pour éviter le problème de scope class_name


func _ready() -> void:
	_setup_camera()
	_setup_grid_visual()
	_setup_placement_preview()
	_setup_hud()
	_setup_settings_panel()
	if debug_spawn_campeur:
		_spawn_test_campeur()


func _unhandled_input(event: InputEvent) -> void:
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


func _setup_settings_panel() -> void:
	var panel := SettingsPanelScript.new()
	panel.name = "SettingsPanel"
	panel.visible = false
	add_child(panel)
