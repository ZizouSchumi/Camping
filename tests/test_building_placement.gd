extends GutTest

# Tests unitaires pour le système de placement de bâtiments (Story 3.1)
# Nécessite GUT addon installé dans addons/gut/

const IDGeneratorScript := preload("res://scripts/utils/id_generator.gd")
const PlacementPreviewScript := preload("res://scenes/ui/construction/placement_preview.gd")

var _preview  # PlacementPreview — non typé, class_name non résolu globalement (extends Node2D + preload)


func before_each() -> void:
	_preview = PlacementPreviewScript.new()
	_preview.visible = false
	add_child(_preview)


func after_each() -> void:
	_preview.queue_free()
	GridSystem.remove(Vector2i(5, 5), Vector2i(2, 2))
	GridSystem.remove(Vector2i(10, 10), Vector2i(2, 2))


func test_batiment_data_defaults() -> void:
	var data := BatimentData.new()
	assert_eq(data.batiment_id, "", "batiment_id doit être vide par défaut")
	assert_eq(data.type_id, "", "type_id doit être vide par défaut")
	assert_eq(data.grid_pos, Vector2i.ZERO, "grid_pos doit être Vector2i.ZERO par défaut")
	assert_eq(data.size, Vector2i(1, 1), "size doit être Vector2i(1,1) par défaut")
	assert_eq(data.rotation_deg, 0, "rotation_deg doit être 0 par défaut")


func test_generate_batiment_id_format() -> void:
	var id: String = IDGeneratorScript.generate_batiment_id()
	assert_true(id.begins_with("b_"), "L'ID doit commencer par 'b_'")
	assert_eq(id.length(), 5, "L'ID doit avoir 5 caractères (b_XXX)")


func test_placement_preview_inactive_par_defaut() -> void:
	assert_false(_preview._active, "Le preview doit être inactif par défaut")
	assert_false(_preview.visible, "Le preview doit être invisible par défaut")


func test_placement_preview_active_apres_activate() -> void:
	_preview.activate("accueil", Vector2i(3, 2))
	assert_true(_preview.visible, "Le preview doit être visible après activate()")
	assert_eq(_preview.preview_size, Vector2i(3, 2), "preview_size doit correspondre à base_size")
	assert_true(_preview._active, "Le preview doit être actif après activate()")


func test_placement_preview_deactivate() -> void:
	_preview.activate("accueil", Vector2i(3, 2))
	_preview.deactivate()
	assert_false(_preview.visible, "Le preview doit être invisible après deactivate()")
	assert_false(_preview._active, "Le preview doit être inactif après deactivate()")


func test_rotate_preview_swap_dimensions() -> void:
	_preview.activate("accueil", Vector2i(3, 2))
	_preview.rotate_preview()
	assert_eq(_preview.preview_size, Vector2i(2, 3), "Les dimensions doivent être permutées après rotate_preview()")


func test_double_rotate_restaure_original() -> void:
	_preview.activate("accueil", Vector2i(3, 2))
	_preview.rotate_preview()
	_preview.rotate_preview()
	assert_eq(_preview.preview_size, Vector2i(3, 2), "Deux rotations doivent restaurer la taille d'origine")


func test_grid_system_place_bloque_cellules() -> void:
	var can_before: bool = GridSystem.can_place("test", Vector2i(5, 5), Vector2i(2, 2))
	assert_true(can_before, "Doit pouvoir placer sur des cellules vides")

	GridSystem.place("b_test", Vector2i(5, 5), Vector2i(2, 2))
	var can_after: bool = GridSystem.can_place("test", Vector2i(5, 5), Vector2i(2, 2))
	assert_false(can_after, "Ne doit plus pouvoir placer sur des cellules occupées")


func test_batiment_construit_event_emis() -> void:
	var received: Dictionary = {}
	var callback := func(payload: Dictionary) -> void:
		received.merge(payload, true)

	EventBus.subscribe("batiment.construit", callback)
	GridSystem.place("b_ev", Vector2i(10, 10), Vector2i(2, 2))
	EventBus.emit("batiment.construit", {
		"entite_id": "b_ev",
		"type_id": "accueil",
		"grid_pos": Vector2i(10, 10),
		"size": Vector2i(2, 2),
		"timestamp": 0.0,
	})

	assert_eq(received.get("type_id"), "accueil", "Le payload doit contenir type_id = 'accueil'")
	assert_eq(received.get("entite_id"), "b_ev", "Le payload doit contenir entite_id = 'b_ev'")

	EventBus.unsubscribe("batiment.construit", callback)
