extends GutTest

# Tests unitaires pour la validation de placement (Story 3.8)
# Couvre : coûts depuis batiments_config.json, vérification budget,
# prérequis Accueil, et désactivation des boutons ConstructionMenu.

const WorldScript := preload("res://scenes/world/world.gd")
const ConstructionMenuScript := preload("res://scenes/ui/construction/construction_menu.gd")

var _argent_sauvegarde: float
var _batiments_sauvegarde: Dictionary
var _world  # WorldScript — instance pour appeler verifier_prerequis / verifier_budget


func before_each() -> void:
	_argent_sauvegarde = GameData.argent
	_batiments_sauvegarde = GameData.batiments.duplicate()
	GameData.argent = 10000.0
	_world = WorldScript.new()


func after_each() -> void:
	GameData.argent = _argent_sauvegarde
	GameData.batiments = _batiments_sauvegarde
	_world.free()
	_world = null


# AC #2 — coût chemin chargé depuis batiments_config.json
func test_cout_chemin_est_50() -> void:
	assert_eq(
		GameData.cout_construction_par_type.get("chemin", -1),
		50,
		"Le coût de construction d'un chemin doit être 50€"
	)


# AC #2 — coût piscine chargé depuis batiments_config.json
func test_cout_piscine_est_2000() -> void:
	assert_eq(
		GameData.cout_construction_par_type.get("piscine", -1),
		2000,
		"Le coût de construction d'une piscine doit être 2000€"
	)


# AC #3 — budget insuffisant → push_error + argent inchangé
func test_budget_insuffisant_push_error() -> void:
	GameData.argent = 100.0
	_world.verifier_budget("snack")  # coût 800€ > 100€
	assert_push_error_count(1, "push_error attendu quand budget insuffisant")
	assert_eq(GameData.argent, 100.0, "argent doit rester inchangé en cas d'échec budget")


# AC #3 — budget suffisant → retourne true, pas d'erreur, argent non modifié par verifier_budget
func test_budget_suffisant_pas_derreur() -> void:
	GameData.argent = 1000.0
	var resultat: bool = _world.verifier_budget("accueil")  # coût 500€
	assert_true(resultat, "verifier_budget doit retourner true avec budget suffisant")
	assert_push_error_count(0, "aucun push_error attendu quand budget suffisant")
	assert_eq(GameData.argent, 1000.0, "verifier_budget ne doit pas modifier l'argent")


# AC #4 — prérequis Accueil absent → push_error
func test_prerequis_accueil_manquant_push_error() -> void:
	GameData.batiments.clear()  # after_each restaure depuis _batiments_sauvegarde
	_world.verifier_prerequis("tente")
	assert_push_error_count(1, "push_error attendu quand Accueil manquant pour emplacement")


# AC #4 — prérequis Accueil présent → pas d'erreur
func test_prerequis_accueil_present_pas_derreur() -> void:
	var accueil := AccueilData.new()
	accueil.type_id = "accueil"
	accueil.batiment_id = "b_test_accueil"
	GameData.batiments["b_test_accueil"] = accueil
	_world.verifier_prerequis("tente")
	assert_push_error_count(0, "aucun push_error attendu quand Accueil présent")


# AC #5 — bouton désactivé si argent < coût à l'initialisation
func test_bouton_desactive_si_budget_insuffisant() -> void:
	GameData.argent = 100.0
	var menu := ConstructionMenuScript.new()
	add_child(menu)
	await get_tree().process_frame

	var btn_piscine: Button = null
	for child in menu.get_children():
		if child is Button and child.get_meta("type_id", "") == "piscine":
			btn_piscine = child
			break

	assert_not_null(btn_piscine, "Le bouton piscine doit exister dans le menu")
	assert_true(btn_piscine.disabled, "Le bouton piscine doit être désactivé quand argent < 2000€")

	menu.queue_free()


# AC #5 — refresh_budget() désactive et réactive les boutons correctement
func test_refresh_budget_met_a_jour_etat_boutons() -> void:
	GameData.argent = 10000.0
	var menu := ConstructionMenuScript.new()
	add_child(menu)
	await get_tree().process_frame

	var btn_piscine: Button = null
	for child in menu.get_children():
		if child is Button and child.get_meta("type_id", "") == "piscine":
			btn_piscine = child
			break

	assert_not_null(btn_piscine, "Le bouton piscine doit exister")
	assert_false(btn_piscine.disabled, "Piscine doit être activée avec 10000€")

	menu.refresh_budget(100.0)
	assert_true(btn_piscine.disabled, "Piscine doit être désactivée après refresh_budget(100)")

	menu.refresh_budget(10000.0)
	assert_false(btn_piscine.disabled, "Piscine doit être réactivée après refresh_budget(10000)")

	menu.queue_free()
