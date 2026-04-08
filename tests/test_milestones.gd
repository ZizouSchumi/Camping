extends GutTest

# Tests S4.7 — Early Wins — Système de milestones (AC: #1, #2)


func before_each() -> void:
	GameData.milestones_atteints.clear()


func test_milestones_initial_vide() -> void:
	assert_eq(GameData.milestones_atteints.size(), 0, "Aucun milestone atteint au départ")


func test_verifier_milestone_retourne_true_premiere_fois() -> void:
	assert_true(GameData.verifier_milestone("premier_batiment"), "Premier appel → true")


func test_verifier_milestone_retourne_false_si_deja_atteint() -> void:
	GameData.verifier_milestone("premier_batiment")
	assert_false(GameData.verifier_milestone("premier_batiment"), "Deuxième appel → false (déjà atteint)")


func test_milestone_marque_apres_premiere_verification() -> void:
	GameData.verifier_milestone("premier_campeur")
	assert_true(GameData.milestones_atteints.get("premier_campeur", false),
		"Milestone marqué true dans milestones_atteints après vérification")


# Comportement intentionnel : premier_avis ne se déclenche QUE sur le premier avis (size==1)
# Si le premier avis est < 3, le milestone ne se déclenche jamais — design voulu.
func test_verifier_milestone_independant_du_contenu_avis() -> void:
	# Simuler un premier avis mauvais (note 1) — le milestone ne doit PAS être marqué
	# (la logique de filtrage note >= 3 est dans world.gd, pas dans verifier_milestone)
	# Ce test vérifie que verifier_milestone lui-même est correct (retourne true 1x, false ensuite)
	assert_true(GameData.verifier_milestone("premier_avis"), "Premier appel → true")
	assert_false(GameData.verifier_milestone("premier_avis"), "Deuxième appel → false (déjà marqué)")
