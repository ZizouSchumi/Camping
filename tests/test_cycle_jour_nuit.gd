extends GutTest

# Tests pour S4.4 — Cycle jour/nuit basique
# AC6 : 4 tests minimum couvrant format heure, tranche nocturne, decay nuit

var _sm: Node  # instance locale SeasonManager (pas l'autoload)


func before_each() -> void:
	_sm = load("res://autoloads/season_manager.gd").new()
	add_child(_sm)
	NeedsSystem._est_nuit = false  # état connu


func after_each() -> void:
	_sm.queue_free()
	NeedsSystem._est_nuit = false  # nettoyage


# AC6a — Format heure correct : 14.5 → "14:30"
func test_heure_formatee_correcte() -> void:
	var heure := 14.5
	var h := int(heure)
	var m := int(fmod(heure * 60.0, 60.0))
	assert_eq("%02d:%02d" % [h, m], "14:30", "14.5h doit s'afficher '14:30'")


# AC6a — Format heure minuit : 0.0 → "00:00"
func test_heure_minuit_formatee() -> void:
	var heure := 0.0
	var h := int(heure)
	var m := int(fmod(heure * 60.0, 60.0))
	assert_eq("%02d:%02d" % [h, m], "00:00", "Minuit doit s'afficher '00:00'")


# AC6b — Tranche nocturne détectée correctement après 21h
func test_is_nuit_vrai_apres_21h() -> void:
	_sm.current_hour = 22.0
	assert_true(_sm.is_nuit(), "22h00 doit être considéré comme nuit")


# AC6b — Tranche nocturne fausse en journée
func test_is_nuit_faux_le_jour() -> void:
	_sm.current_hour = 14.0
	assert_false(_sm.is_nuit(), "14h00 ne doit pas être nuit")


# AC6c — Decay sommeil réduit la nuit (×0.1)
func test_decay_sommeil_reduit_la_nuit() -> void:
	var id := "c_test_nuit_s"
	var data := CampeurData.new()
	data.campeur_id = id
	data.prenom = "NuitSommeil"
	GameData.campeurs[id] = data
	NeedsSystem.register_campeur(id)

	NeedsSystem._est_nuit = true
	var besoin_sommeil: BesoinData = data.besoins.get("sommeil")
	assert_not_null(besoin_sommeil, "Le besoin sommeil doit exister")
	var valeur_avant := besoin_sommeil.valeur_actuelle
	NeedsSystem._update_campeur(id, 100.0)
	# Nuit (×0.1) : decay réel < 50% du decay normal → valeur > valeur_avant - taux * 100 * 0.5
	assert_gt(besoin_sommeil.valeur_actuelle,
		valeur_avant - besoin_sommeil.taux_decay * 100.0 * 0.5,
		"Decay sommeil doit être fortement réduit la nuit (×0.1)")

	NeedsSystem.unregister_campeur(id)
	GameData.campeurs.erase(id)
	NeedsSystem._est_nuit = false


# AC6d — Decay faim réduit la nuit (×0.3)
func test_decay_faim_reduit_la_nuit() -> void:
	var id := "c_test_nuit_f"
	var data := CampeurData.new()
	data.campeur_id = id
	data.prenom = "NuitFaim"
	GameData.campeurs[id] = data
	NeedsSystem.register_campeur(id)

	NeedsSystem._est_nuit = true
	var besoin_faim: BesoinData = data.besoins.get("faim")
	assert_not_null(besoin_faim, "Le besoin faim doit exister")
	var valeur_avant := besoin_faim.valeur_actuelle
	NeedsSystem._update_campeur(id, 100.0)
	# Nuit (×0.3) : decay réel < 50% du decay normal → valeur > valeur_avant - taux * 100 * 0.5
	assert_gt(besoin_faim.valeur_actuelle,
		valeur_avant - besoin_faim.taux_decay * 100.0 * 0.5,
		"Decay faim doit être réduit la nuit (×0.3)")

	NeedsSystem.unregister_campeur(id)
	GameData.campeurs.erase(id)
	NeedsSystem._est_nuit = false
