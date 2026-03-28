extends GutTest

# tests/test_fiche_campeur.gd
# Tests unitaires pour CampeurFiche (S2.6) et UIManager

const CampeurFicheScript := preload("res://scenes/ui/campeur/campeur_fiche.gd")

var _test_campeur_id: String = "c_test_fiche01"
var _fiche: CampeurFicheScript


func before_each() -> void:
	var data := CampeurData.new()
	data.campeur_id = _test_campeur_id
	data.prenom = "Marcel"
	data.age = 45
	data.genre = "homme"
	data.date_arrivee = 0.0
	data.date_depart_prevue = 7.0
	GameData.campeurs[_test_campeur_id] = data
	NeedsSystem.register_campeur(_test_campeur_id)  # initialise besoins + personnalite

	_fiche = CampeurFicheScript.new()
	add_child(_fiche)
	await get_tree().process_frame  # Attendre _ready() / _build_ui()


func after_each() -> void:
	NeedsSystem.unregister_campeur(_test_campeur_id)
	GameData.campeurs.erase(_test_campeur_id)
	if is_instance_valid(_fiche):
		_fiche.queue_free()
	await get_tree().process_frame
	UIManager.close("campeur_fiche")  # Nettoyage si test UIManager a laissé un panneau


func test_initialize_valide() -> void:
	_fiche.initialize(_test_campeur_id)
	assert_eq(_fiche._label_prenom.text, "Marcel", "Prénom affiché correctement")
	assert_eq(_fiche._label_age.text, "45 ans", "Age affiché correctement")
	assert_eq(_fiche._label_genre.text, "homme", "Genre affiché correctement")


func test_initialize_campeur_inconnu() -> void:
	_fiche.initialize("c_inexistant_xyz")
	assert_push_error_count(1, "push_error attendu pour campeur_id inconnu")


func test_initialize_personnalite_null() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	data.personnalite = null
	_fiche.initialize(_test_campeur_id)
	assert_false(_fiche._section_personnalite.visible, "Section personnalité masquée si null")


func test_calcul_duree_sejour() -> void:
	_fiche.initialize(_test_campeur_id)
	assert_eq(_fiche._label_sejour.text, "7 jour(s)", "Durée de séjour calculée correctement")


func test_duree_sejour_inconnue() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	data.date_depart_prevue = 0.0  # depart <= arrivee → durée nulle
	_fiche.initialize(_test_campeur_id)
	assert_eq(_fiche._label_sejour.text, "Durée inconnue", "'Durée inconnue' si depart <= arrivee")


func test_ui_manager_open_idempotent() -> void:
	UIManager.open("campeur_fiche", {"campeur_id": _test_campeur_id})
	UIManager.open("campeur_fiche", {"campeur_id": _test_campeur_id})
	assert_eq(UIManager._panels.size(), 1, "UIManager ouvre au maximum 1 instance du même panneau")
	UIManager.close("campeur_fiche")
	assert_false(UIManager._panels.has("campeur_fiche"), "Panneau fermé correctement")
