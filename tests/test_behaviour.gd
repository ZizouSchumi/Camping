extends GutTest

# Tests unitaires pour le comportement autonome — S2.5
# Couvre : StateMachine, UtilityEvaluator, boucle de décision NeedsSystem, satisfaction sur arrivée.
# NeedsSystem, GameData et EventBus sont des autoloads — déjà instanciés lors des tests GUT.

var _test_campeur_id: String = "c_test_b01"
var _deplacer_count: int = 0
var _deplacer_callback: Callable


func before_each() -> void:
	_deplacer_count = 0
	_deplacer_callback = func(p: Dictionary) -> void:
		if p.get("entite_id", "") == _test_campeur_id:
			_deplacer_count += 1
	EventBus.subscribe("campeur.deplacer_vers", _deplacer_callback)

	var data := CampeurData.new()
	data.campeur_id = _test_campeur_id
	data.prenom = "TestBehaviour"
	GameData.campeurs[_test_campeur_id] = data
	NeedsSystem.register_campeur(_test_campeur_id)


func after_each() -> void:
	EventBus.unsubscribe("campeur.deplacer_vers", _deplacer_callback)
	NeedsSystem.unregister_campeur(_test_campeur_id)
	GameData.campeurs.erase(_test_campeur_id)


# AC8a — après register_campeur, _state_machines contient le campeur en état IDLE
func test_state_machine_initial_idle() -> void:
	assert_true(
		NeedsSystem._state_machines.has(_test_campeur_id),
		"StateMachine créée au register_campeur"
	)
	var sm: StateMachine = NeedsSystem._state_machines[_test_campeur_id]
	assert_eq(sm.etat, StateMachine.Etat.IDLE, "État initial = IDLE")


# AC8b — besoin non satisfait + timer expiré → événement "campeur.deplacer_vers" émis
func test_besoin_non_satisfait_emet_deplacer_vers() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	data.besoins["faim"].valeur_actuelle = 0.3
	# Le timer démarre entre 0 et DECISION_INTERVAL — ajouter DECISION_INTERVAL + marge garantit qu'il expire
	NeedsSystem._update_campeur(_test_campeur_id, StateMachine.DECISION_INTERVAL + 0.1)
	assert_gt(_deplacer_count, 0, "Événement deplacer_vers émis pour besoin urgent")


# AC8c — tous les besoins satisfaits → aucun événement "campeur.deplacer_vers"
func test_tous_satisfaits_pas_deplacer_vers() -> void:
	# valeur_initiale = 0.8 > seuil_satisfait = 0.7 → tous satisfaits par défaut
	NeedsSystem._update_campeur(_test_campeur_id, StateMachine.DECISION_INTERVAL + 0.1)
	assert_eq(_deplacer_count, 0, "Aucun événement si tous les besoins satisfaits")


# AC8d — _on_destination_atteinte avec payload valide → besoin satisfait, état retourne IDLE
func test_destination_atteinte_satisfait_besoin() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	data.besoins["faim"].valeur_actuelle = 0.3
	# Déclencher décision → SM passe en WALKING
	NeedsSystem._update_campeur(_test_campeur_id, StateMachine.DECISION_INTERVAL + 0.1)
	var sm: StateMachine = NeedsSystem._state_machines[_test_campeur_id]
	assert_eq(sm.etat, StateMachine.Etat.WALKING, "SM en WALKING après décision")
	# Vérifier quel besoin a été choisi, puis capturer sa valeur
	var besoin_cible: String = sm.besoin_cible
	assert_ne(besoin_cible, "", "besoin_cible défini après décision")
	assert_true(data.besoins.has(besoin_cible), "besoin_cible existe dans les besoins du campeur")
	var valeur_avant: float = data.besoins[besoin_cible].valeur_actuelle
	# Simuler arrivée à destination
	NeedsSystem._on_destination_atteinte({
		"entite_id": _test_campeur_id,
		"timestamp": 0.0,
		"position": Vector2.ZERO,
	})
	assert_gt(data.besoins[besoin_cible].valeur_actuelle, valeur_avant, "Besoin satisfait après arrivée")
	assert_eq(sm.etat, StateMachine.Etat.IDLE, "Retour en IDLE après satisfaction")


# AC8e — timeout WALKING : timer >= MAX_WALK_TIME → retour IDLE sans satisfaction
func test_walking_timeout_retour_idle() -> void:
	var data: CampeurData = GameData.campeurs[_test_campeur_id]
	data.besoins["faim"].valeur_actuelle = 0.3
	# Déclencher décision → WALKING
	NeedsSystem._update_campeur(_test_campeur_id, StateMachine.DECISION_INTERVAL + 0.1)
	# Avancer jusqu'au timeout — timer reset à 0 lors de transition_vers(WALKING)
	NeedsSystem._update_campeur(_test_campeur_id, StateMachine.MAX_WALK_TIME + 0.1)
	var sm: StateMachine = NeedsSystem._state_machines[_test_campeur_id]
	assert_eq(sm.etat, StateMachine.Etat.IDLE, "Retour IDLE après timeout WALKING")
	# Vérifier qu'une nouvelle décision est possible après le timeout
	var deplacer_avant := _deplacer_count
	NeedsSystem._update_campeur(_test_campeur_id, StateMachine.DECISION_INTERVAL + 0.1)
	assert_gt(_deplacer_count, deplacer_avant, "Nouvelle décision possible après timeout")


# AC8f — UtilityEvaluator.score_besoin : score croissant quand valeur_actuelle décroît
func test_utility_evaluator_score() -> void:
	var besoin := BesoinData.new()
	besoin.modificateur_decay = 1.0

	besoin.valeur_actuelle = 1.0
	var score_satisfait := UtilityEvaluator.score_besoin(besoin)
	assert_almost_eq(score_satisfait, 0.0, 0.0001, "Score = 0 quand besoin satisfait à 1.0")

	besoin.valeur_actuelle = 0.5
	var score_moyen := UtilityEvaluator.score_besoin(besoin)

	besoin.valeur_actuelle = 0.1
	var score_urgent := UtilityEvaluator.score_besoin(besoin)

	assert_gt(score_urgent, score_moyen, "Score augmente quand valeur_actuelle diminue")
	assert_gt(score_moyen, score_satisfait, "Score intermédiaire > score satisfait")
