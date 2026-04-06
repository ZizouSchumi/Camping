extends GutTest

# Tests unitaires — Story 4.1 : Simulation simultanée de 2 campeurs
# Valide que NeedsSystem gère 2 campeurs en parallèle sans conflit.

var _id_a := "c_test_001"
var _id_b := "c_test_002"


func before_each() -> void:
	var data_a := CampeurData.new()
	data_a.campeur_id = _id_a
	data_a.prenom = "TestA"
	GameData.campeurs[_id_a] = data_a
	NeedsSystem.register_campeur(_id_a)

	var data_b := CampeurData.new()
	data_b.campeur_id = _id_b
	data_b.prenom = "TestB"
	GameData.campeurs[_id_b] = data_b
	NeedsSystem.register_campeur(_id_b)


func after_each() -> void:
	NeedsSystem.unregister_campeur(_id_a)
	NeedsSystem.unregister_campeur(_id_b)
	GameData.campeurs.erase(_id_a)
	GameData.campeurs.erase(_id_b)


# AC #2 — Les 2 campeurs sont bien enregistrés dans NeedsSystem simultanément
func test_deux_campeurs_enregistres_simultanement() -> void:
	assert_true(NeedsSystem._registered_campeurs.has(_id_a), "c_test_001 enregistré dans NeedsSystem")
	assert_true(NeedsSystem._registered_campeurs.has(_id_b), "c_test_002 enregistré dans NeedsSystem")


# AC #1 — Les 2 CampeurData sont distincts dans GameData
func test_deux_campeurdata_distincts_dans_gamedata() -> void:
	assert_true(GameData.campeurs.has(_id_a), "GameData contient c_test_001")
	assert_true(GameData.campeurs.has(_id_b), "GameData contient c_test_002")
	assert_ne(GameData.campeurs[_id_a], GameData.campeurs[_id_b], "Les deux CampeurData sont des objets distincts")


# AC #3 — update des 2 campeurs sans push_error
func test_update_deux_campeurs_sans_erreur() -> void:
	# Reset timers pour éviter le déclenchement non-déterministe de _evaluer_et_agir
	NeedsSystem._state_machines[_id_a].timer = 0.0
	NeedsSystem._state_machines[_id_b].timer = 0.0
	NeedsSystem._update_campeur(_id_a, 0.01)
	NeedsSystem._update_campeur(_id_b, 0.01)
	assert_push_error_count(0, "update_campeur des 2 campeurs sans erreur")


# AC #2 — unregister nettoie bien les 2
func test_unregister_nettoie_les_deux() -> void:
	NeedsSystem.unregister_campeur(_id_a)
	NeedsSystem.unregister_campeur(_id_b)
	assert_false(NeedsSystem._registered_campeurs.has(_id_a), "c_test_001 retiré de NeedsSystem")
	assert_false(NeedsSystem._registered_campeurs.has(_id_b), "c_test_002 retiré de NeedsSystem")


# AC #7 — decay indépendant : _update_campeur sur c_001 ne modifie pas les besoins de c_002
func test_besoins_independants() -> void:
	var besoins_b: Dictionary = GameData.campeurs[_id_b].besoins
	var besoin_b: BesoinData = besoins_b.get("faim") as BesoinData
	if besoin_b == null:
		return  # "faim" absent de besoins_config — test non applicable
	var valeur_avant: float = besoin_b.valeur_actuelle
	# Reset timer pour éviter déclenchement AI — on teste uniquement le decay
	NeedsSystem._state_machines[_id_a].timer = 0.0
	NeedsSystem._update_campeur(_id_a, 0.01)
	assert_eq(besoin_b.valeur_actuelle, valeur_avant, "Le decay de _id_a ne modifie pas les besoins de _id_b")
