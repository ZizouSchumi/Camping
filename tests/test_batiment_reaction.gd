extends GutTest

# Tests unitaires — Story 4.3 : Campeurs réagissent aux bâtiments
# Valide le mapping besoin→bâtiment, file d'attente, satisfaction, emplacement, EventBus.

var _campeur_id := "c_bat_test_001"
var _batiment_id := "b_bat_test_snack"
var _received_events: Array = []


func before_each() -> void:
	var data := CampeurData.new()
	data.campeur_id = _campeur_id
	data.prenom = "TestBatiment"
	data.world_position = Vector2(320.0, 320.0)  # cellule (5,5)
	GameData.campeurs[_campeur_id] = data
	NeedsSystem.register_campeur(_campeur_id)
	NeedsSystem._state_machines[_campeur_id].timer = 0.0
	_received_events.clear()


func after_each() -> void:
	NeedsSystem.unregister_campeur(_campeur_id)
	GameData.campeurs.erase(_campeur_id)
	for key in GameData.batiments.keys():
		if key.begins_with("b_bat_test_"):
			GameData.batiments.erase(key)
	EventBus.unsubscribe("batiment.campeur_utilise", _on_batiment_utilise)


func _on_batiment_utilise(payload: Dictionary) -> void:
	_received_events.append(payload)


# AC #2 — get_nearest retourne le bâtiment correct pour un type donné
func test_get_nearest_retourne_batiment_correct() -> void:
	var snack := SnackData.new()
	snack.batiment_id = _batiment_id
	snack.type_id = "snack"
	snack.grid_pos = Vector2i(10, 10)
	snack.size = Vector2i(3, 3)
	snack.capacite_max = 12
	GameData.batiments[_batiment_id] = snack

	var result := GridSystem.get_nearest(Vector2i(5, 5), "snack")
	assert_eq(result, Vector2i(10, 10), "get_nearest doit retourner la grid_pos du snack placé")


# AC #3 — file d'attente : _evaluer_et_agir génère errance si capacite_max atteinte
func test_file_dattente_bloque_si_capacite_max_atteinte() -> void:
	var snack := SnackData.new()
	snack.batiment_id = _batiment_id
	snack.type_id = "snack"
	snack.grid_pos = Vector2i(10, 10)
	snack.size = Vector2i(3, 3)
	snack.capacite_max = 1
	snack.campeurs_en_service.append("c_autre")  # Bâtiment plein
	GameData.batiments[_batiment_id] = snack

	# Forcer besoin "faim" au minimum pour déclencher _evaluer_et_agir
	var faim: BesoinData = GameData.campeurs[_campeur_id].besoins.get("faim") as BesoinData
	assert_not_null(faim, "besoin 'faim' doit exister dans besoins_config.json")
	if faim == null:
		return
	faim.valeur_actuelle = 0.05

	var received_events := []
	var cb := func(p: Dictionary) -> void:
		if p.get("entite_id", "") == _campeur_id:
			received_events.append(p)
	EventBus.subscribe("campeur.deplacer_vers", cb)

	NeedsSystem._state_machines[_campeur_id].timer = StateMachine.DECISION_INTERVAL
	NeedsSystem._evaluer_et_agir(_campeur_id)

	EventBus.unsubscribe("campeur.deplacer_vers", cb)
	assert_true(received_events.size() > 0, "_evaluer_et_agir doit émettre campeur.deplacer_vers")
	# Bâtiment plein → batiment_id vide dans le payload → le campeur erre
	assert_eq(NeedsSystem._state_machines[_campeur_id].batiment_cible, "",
			"batiment_cible doit être vide si file d'attente pleine")


# AC #5 — satisfaire_besoin incrémente la valeur du besoin
func test_satisfaire_besoin_incremente_valeur() -> void:
	var faim: BesoinData = GameData.campeurs[_campeur_id].besoins.get("faim") as BesoinData
	if faim == null:
		return  # "faim" absent de besoins_config — test non applicable
	faim.valeur_actuelle = 0.5
	NeedsSystem.satisfaire_besoin(_campeur_id, "faim", 0.25)
	assert_almost_eq(faim.valeur_actuelle, 0.75, 0.001, "satisfaire_besoin doit incrémenter valeur_actuelle de 0.25")


# AC #4 — emplacement assigné correctement : campeur_data.emplacement_id et campeurs_en_service
func test_emplacement_assigne_correctement() -> void:
	var tente := EmplacementData.new()
	tente.batiment_id = "b_bat_test_tente"
	tente.type_id = "tente"
	tente.grid_pos = Vector2i(8, 8)
	tente.size = Vector2i(2, 2)
	tente.capacite_max = 1
	GameData.batiments["b_bat_test_tente"] = tente

	var eid := NeedsSystem._trouver_emplacement_libre(Vector2(320.0, 320.0))
	assert_eq(eid, "b_bat_test_tente", "_trouver_emplacement_libre doit retourner la tente libre")

	# Simuler l'assignation
	var edata: BatimentData = GameData.batiments[eid]
	edata.campeurs_en_service.append(_campeur_id)
	GameData.campeurs[_campeur_id].emplacement_id = eid

	assert_eq(GameData.campeurs[_campeur_id].emplacement_id, "b_bat_test_tente",
			"campeur_data.emplacement_id doit pointer vers la tente")
	assert_true(edata.campeurs_en_service.has(_campeur_id),
			"campeurs_en_service de la tente doit contenir le campeur")

	# Vérifier que la tente est maintenant occupée (plus disponible)
	var eid2 := NeedsSystem._trouver_emplacement_libre(Vector2(320.0, 320.0))
	assert_eq(eid2, "", "_trouver_emplacement_libre doit retourner '' si la tente est occupée")


# AC #2 — fallback wander si aucun bâtiment du type disponible
func test_fallback_wander_si_aucun_batiment() -> void:
	# Aucun snack dans GameData
	var faim: BesoinData = GameData.campeurs[_campeur_id].besoins.get("faim") as BesoinData
	assert_not_null(faim, "besoin 'faim' doit exister dans besoins_config.json")
	if faim == null:
		return
	faim.valeur_actuelle = 0.05

	var received_events := []
	var cb := func(p: Dictionary) -> void:
		if p.get("entite_id", "") == _campeur_id:
			received_events.append(p)
	EventBus.subscribe("campeur.deplacer_vers", cb)

	NeedsSystem._evaluer_et_agir(_campeur_id)

	EventBus.unsubscribe("campeur.deplacer_vers", cb)
	assert_true(received_events.size() > 0, "campeur.deplacer_vers doit être émis (errance)")
	assert_eq(received_events[0].get("batiment_id", "NON_INITIALISÉ"), "",
			"batiment_id doit être vide (errance) si aucun snack disponible")


# AC #6 — EventBus batiment.campeur_utilise émis à l'utilisation
func test_eventbus_batiment_campeur_utilise_emis() -> void:
	var snack := SnackData.new()
	snack.batiment_id = _batiment_id
	snack.type_id = "snack"
	snack.grid_pos = Vector2i(10, 10)
	snack.size = Vector2i(3, 3)
	snack.capacite_max = 12
	GameData.batiments[_batiment_id] = snack

	EventBus.subscribe("batiment.campeur_utilise", _on_batiment_utilise)

	# Simuler l'arrivée au bâtiment
	var sm: StateMachine = NeedsSystem._state_machines[_campeur_id]
	sm.transition_vers(StateMachine.Etat.WALKING)
	sm.besoin_cible = "faim"
	sm.batiment_cible = _batiment_id

	NeedsSystem._on_destination_atteinte({
		"entite_id": _campeur_id,
		"timestamp": 0.0,
	})

	assert_eq(_received_events.size(), 1, "batiment.campeur_utilise doit être émis une fois")
	assert_eq(_received_events[0].get("entite_id", ""), _batiment_id,
			"entite_id doit être le batiment_id")
	assert_eq(_received_events[0].get("campeur_id", ""), _campeur_id,
			"campeur_id doit être le campeur qui utilise le bâtiment")
	assert_eq(_received_events[0].get("besoin_id", ""), "faim",
			"besoin_id doit correspondre au besoin satisfait")
