extends GutTest

# Tests unitaires pour NeedsSystem (Story 2.2)
# NeedsSystem et GameData sont des autoloads — déjà instanciés lors des tests GUT.

var _test_campeur_id: String = "c_test_001"
var _critique_count: int = 0
var _critique_callback: Callable


func before_each() -> void:
	_critique_count = 0
	_critique_callback = func(_p: Dictionary) -> void:
		_critique_count += 1
	EventBus.subscribe("besoin.critique", _critique_callback)

	var data := CampeurData.new()
	data.campeur_id = _test_campeur_id
	data.prenom = "TestCampeur"
	GameData.campeurs[_test_campeur_id] = data
	NeedsSystem.register_campeur(_test_campeur_id)


func after_each() -> void:
	EventBus.unsubscribe("besoin.critique", _critique_callback)
	NeedsSystem.unregister_campeur(_test_campeur_id)
	GameData.campeurs.erase(_test_campeur_id)


# AC8a — register_campeur initialise exactement 9 besoins
func test_register_initialise_9_besoins() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	assert_eq(data.besoins.size(), 9, "Exactement 9 besoins initialisés")


# Vérification des niveaux des besoins initialisés
func test_besoins_ont_les_niveaux_corrects() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	assert_true(data.besoins.has("faim"), "faim présent")
	assert_eq(data.besoins["faim"].niveau, "primaire", "faim est primaire")
	assert_true(data.besoins.has("socialiser"), "socialiser présent")
	assert_eq(data.besoins["socialiser"].niveau, "secondaire", "socialiser est secondaire")
	assert_true(data.besoins.has("bien_etre"), "bien_etre présent")
	assert_eq(data.besoins["bien_etre"].niveau, "tertiaire", "bien_etre est tertiaire")


# AC8b — decay après mise à jour simulée → valeur diminuée
func test_decay_diminue_valeur() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	var valeur_avant: float = data.besoins["faim"].valeur_actuelle
	NeedsSystem._update_campeur(_test_campeur_id, 10.0)  # 10 secondes de jeu
	assert_lt(data.besoins["faim"].valeur_actuelle, valeur_avant, "Valeur a diminué après decay")


# Valeur clampée à 0.0 minimum
func test_valeur_clampee_a_zero() -> void:
	NeedsSystem._update_campeur(_test_campeur_id, 10000.0)  # Très long delta
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	for besoin_id in data.besoins:
		assert_gte(data.besoins[besoin_id].valeur_actuelle, 0.0, "Valeur >= 0.0 pour " + besoin_id)


# AC8c — get_besoin_prioritaire retourne un primaire avant un secondaire critique
func test_priorite_primaire_avant_secondaire() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	# faim (primaire) à 0.3 (non-satisfait), socialiser (secondaire) à 0.05 (critique)
	data.besoins["faim"].valeur_actuelle = 0.3
	data.besoins["socialiser"].valeur_actuelle = 0.05
	var prioritaire: BesoinData = NeedsSystem.get_besoin_prioritaire(_test_campeur_id)
	assert_not_null(prioritaire, "Un besoin prioritaire trouvé")
	assert_eq(prioritaire.besoin_id, "faim", "faim (primaire) prend la priorité sur socialiser critique (secondaire)")


# null si tous les besoins sont satisfaits
func test_get_besoin_prioritaire_null_si_tout_satisfait() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	for besoin_id in data.besoins:
		data.besoins[besoin_id].valeur_actuelle = 1.0
	var prioritaire: BesoinData = NeedsSystem.get_besoin_prioritaire(_test_campeur_id)
	assert_null(prioritaire, "null si tous les besoins sont satisfaits")


# AC8d — event "besoin.critique" émis exactement une fois par transition
func test_critique_emis_une_fois() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	# Forcer faim juste au-dessus du seuil critique (0.2 + 0.001 = 0.201)
	# taux_decay faim = 0.002/s → 0.201 - 0.002 * 1.0 = 0.199 < 0.2 ✓
	data.besoins["faim"].valeur_actuelle = 0.201

	# Premier update : passe sous seuil_critique → event doit être émis
	NeedsSystem._update_campeur(_test_campeur_id, 1.0)
	var count_apres_premier: int = _critique_count

	# Deuxième update : déjà critique → event NE doit PAS être émis à nouveau
	NeedsSystem._update_campeur(_test_campeur_id, 1.0)
	assert_eq(_critique_count, count_apres_premier, "Event critique émis une seule fois par transition")
	assert_gt(_critique_count, 0, "Event critique émis au moins une fois")


# AC8e — satisfaire_besoin incrémente correctement
func test_satisfaire_besoin() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	data.besoins["faim"].valeur_actuelle = 0.3
	NeedsSystem.satisfaire_besoin(_test_campeur_id, "faim", 0.5)
	assert_almost_eq(data.besoins["faim"].valeur_actuelle, 0.8, 0.001, "Valeur incrémentée à 0.8")


# satisfaire_besoin clampé à 1.0
func test_satisfaire_besoin_clampe_a_1() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	data.besoins["faim"].valeur_actuelle = 0.9
	NeedsSystem.satisfaire_besoin(_test_campeur_id, "faim", 0.5)
	assert_almost_eq(data.besoins["faim"].valeur_actuelle, 1.0, 0.001, "Valeur clampée à 1.0")


# AC4 — pause : aucun decay quand en_pause = true
func test_pause_arrete_le_decay() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	var valeur_avant: float = data.besoins["faim"].valeur_actuelle
	NeedsSystem._on_vitesse_change({"vitesse": 1.0, "en_pause": true})
	NeedsSystem._process(1.0)
	assert_eq(data.besoins["faim"].valeur_actuelle, valeur_avant, "Aucun decay quand en pause")
	NeedsSystem._on_vitesse_change({"vitesse": 1.0, "en_pause": false})


# AC4 — time_scale : x2 pendant 1s = x1 pendant 2s
func test_time_scale_double_le_decay() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	var valeur_initiale: float = data.besoins["faim"].valeur_actuelle

	NeedsSystem._on_vitesse_change({"vitesse": 2.0, "en_pause": false})
	NeedsSystem._process(1.0)
	var decay_x2: float = valeur_initiale - data.besoins["faim"].valeur_actuelle

	data.besoins["faim"].valeur_actuelle = valeur_initiale
	NeedsSystem._on_vitesse_change({"vitesse": 1.0, "en_pause": false})
	NeedsSystem._process(2.0)
	var decay_x1_x2s: float = valeur_initiale - data.besoins["faim"].valeur_actuelle

	assert_almost_eq(decay_x2, decay_x1_x2s, 0.0001, "x2 scale 1s == x1 scale 2s")
	NeedsSystem._on_vitesse_change({"vitesse": 1.0, "en_pause": false})


# AC5 — get_besoin_prioritaire avec campeur inexistant → null + push_error attendu
func test_get_besoin_prioritaire_campeur_inexistant() -> void:
	var prioritaire: BesoinData = NeedsSystem.get_besoin_prioritaire("c_inexistant_999")
	assert_null(prioritaire, "null retourné pour campeur inexistant")
	assert_push_error_count(1, "push_error attendu pour campeur inexistant")


# AC7 — satisfaire_besoin avec campeur inexistant → push_error attendu
func test_satisfaire_besoin_campeur_inexistant() -> void:
	NeedsSystem.satisfaire_besoin("c_inexistant_999", "faim", 0.5)
	assert_push_error_count(1, "push_error attendu pour campeur inexistant")


# AC7 — satisfaire_besoin avec besoin_id inexistant → push_error attendu
func test_satisfaire_besoin_besoin_inexistant() -> void:
	NeedsSystem.satisfaire_besoin(_test_campeur_id, "besoin_inexistant_999", 0.5)
	assert_push_error_count(1, "push_error attendu pour besoin inexistant")
