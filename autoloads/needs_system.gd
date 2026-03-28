extends Node

# NeedsSystem — boucle centralisée de mise à jour des besoins de TOUS les PNJ
# UNE seule boucle pour N campeurs — jamais de boucle individuelle par campeur
#
# CONTRAINTE ARCHITECTURALE : NeedsSystem est l'autoload #5.
# Il NE peut PAS référencer SeasonManager (autoload #6).
# La synchronisation vitesse/pause passe exclusivement par EventBus "jeu.vitesse_change".

var _registered_campeurs: Array[String] = []
var _besoins_config: Array = []           # Chargé depuis besoins_config.json
var _personnalite_config: Dictionary = {} # Chargé depuis personnalites_config.json
var _time_scale: float = 1.0              # Synchronisé via EventBus, PAS SeasonManager
var _paused: bool = false                 # Synchronisé via EventBus, PAS SeasonManager
var _elapsed_game_time: float = 0.0       # Équivalent local de SeasonManager.current_time
										  # TODO S3+: synchroniser depuis SaveSystem.load_game() pour éviter
										  # la désync des timestamps "besoin.critique" après rechargement de save
										  # TODO S3+: après load_game(), rappeler register_campeur() (ou
										  # initialiser_personnalite()) pour chaque campeur chargé — BesoinData.modificateur_decay
										  # n'est pas @export donc non persisté ; doit être recalculé depuis CampeurData.personnalite
var _critique_notified: Dictionary = {}   # campeur_id → Array[String] de besoin_ids en état critique
var _lod_factors: Dictionary = {}         # campeur_id → float (1.0 = full update, < 1.0 = réduit)
var _state_machines: Dictionary = {}      # campeur_id → StateMachine (S2.5)
# Buffers pré-alloués pour get_besoin_prioritaire — évite les allocs GC dans la boucle AI (S2.5)
var _prio_primaires: Array[BesoinData] = []
var _prio_secondaires: Array[BesoinData] = []
var _prio_tertiaires: Array[BesoinData] = []


func _ready() -> void:
	_load_besoins_config()
	_load_personnalites_config()
	EventBus.subscribe("jeu.vitesse_change", _on_vitesse_change)
	EventBus.subscribe("campeur.destination_atteinte", _on_destination_atteinte)


func _load_besoins_config() -> void:
	var file := FileAccess.open("res://assets/data/besoins_config.json", FileAccess.READ)
	if not file:
		push_error("NeedsSystem: impossible d'ouvrir besoins_config.json")
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("NeedsSystem: JSON invalide dans besoins_config.json — ligne " + str(json.get_error_line()))
		return
	_besoins_config = json.data.get("besoins", [])
	if _besoins_config.is_empty():
		push_error("NeedsSystem: aucun besoin trouvé dans besoins_config.json")


func _load_personnalites_config() -> void:
	var file := FileAccess.open("res://assets/data/personnalites_config.json", FileAccess.READ)
	if not file:
		push_warning("NeedsSystem: personnalites_config.json absent — personnalités désactivées")
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("NeedsSystem: JSON invalide dans personnalites_config.json — personnalités désactivées")
		return
	_personnalite_config = json.data
	if not _personnalite_config.has("poids_besoins"):
		push_warning("NeedsSystem: poids_besoins absent dans personnalites_config.json — personnalités désactivées")
		_personnalite_config = {}


func _on_vitesse_change(payload: Dictionary) -> void:
	_time_scale = payload.get("vitesse", 1.0)
	_paused = payload.get("en_pause", false)


func _process(delta: float) -> void:
	if _paused:
		return
	var game_delta: float = delta * _time_scale
	_elapsed_game_time += game_delta
	for campeur_id in _registered_campeurs.duplicate():
		_update_campeur(campeur_id, game_delta)


func register_campeur(campeur_id: String) -> void:
	if campeur_id in _registered_campeurs:
		return
	_registered_campeurs.append(campeur_id)
	_critique_notified[campeur_id] = []
	_lod_factors[campeur_id] = 1.0
	_initialiser_besoins(campeur_id)
	_initialiser_personnalite(campeur_id)
	var sm := StateMachine.new()
	sm.timer = randf_range(0.0, StateMachine.DECISION_INTERVAL)
	_state_machines[campeur_id] = sm


func unregister_campeur(campeur_id: String) -> void:
	_registered_campeurs.erase(campeur_id)
	_critique_notified.erase(campeur_id)
	_lod_factors.erase(campeur_id)
	_state_machines.erase(campeur_id)


func _initialiser_personnalite(campeur_id: String) -> void:
	if not GameData.campeurs.has(campeur_id):
		return
	var data: CampeurData = GameData.campeurs[campeur_id]
	if data.personnalite == null:
		var p := PersonnaliteData.new()
		p.sociabilite = randf()
		p.vitalite    = randf()
		p.appetit     = randf()
		p.exigence    = randf()
		p.zenitude    = randf()
		data.personnalite = p
	_appliquer_poids_personnalite(campeur_id)


func _appliquer_poids_personnalite(campeur_id: String) -> void:
	if _personnalite_config.is_empty():
		return  # Config absente — modificateurs restent à 1.0
	if not GameData.campeurs.has(campeur_id):
		return
	var data: CampeurData = GameData.campeurs[campeur_id]
	if data.personnalite == null:
		return
	var poids_map: Dictionary = _personnalite_config.get("poids_besoins", {})
	for besoin_id in data.besoins:
		var besoin: BesoinData = data.besoins[besoin_id]
		if not poids_map.has(besoin_id):
			continue  # Besoin sans mapping → modificateur reste à 1.0
		var cfg: Dictionary = poids_map[besoin_id]
		var axe_val: float = data.personnalite.get_axe(cfg.get("axe", ""))
		besoin.modificateur_decay = lerpf(
			cfg.get("min_poids", 1.0),
			cfg.get("max_poids", 1.0),
			axe_val
		)


func initialiser_personnalite(campeur_id: String, personnalite: PersonnaliteData) -> void:
	if not GameData.campeurs.has(campeur_id):
		push_error("NeedsSystem.initialiser_personnalite: campeur introuvable — " + campeur_id)
		return
	GameData.campeurs[campeur_id].personnalite = personnalite
	_appliquer_poids_personnalite(campeur_id)


func _initialiser_besoins(campeur_id: String) -> void:
	if not GameData.campeurs.has(campeur_id):
		push_error("NeedsSystem._initialiser_besoins: campeur introuvable — " + campeur_id)
		return
	var data: CampeurData = GameData.campeurs[campeur_id]
	data.besoins = {}
	for config in _besoins_config:
		var besoin := BesoinData.new()
		besoin.besoin_id = config.get("id", "")
		besoin.niveau = config.get("niveau", "primaire")
		besoin.valeur_actuelle = config.get("valeur_initiale", 0.8)
		besoin.taux_decay = config.get("taux_decay", 0.001)
		besoin.seuil_critique = config.get("seuil_critique", 0.2)
		besoin.seuil_eleve = config.get("seuil_eleve", 0.4)
		besoin.seuil_satisfait = config.get("seuil_satisfait", 0.7)
		data.besoins[besoin.besoin_id] = besoin


# TEST-ONLY: exposé pour permettre les tests GUT directs (bypass _process/_paused/_time_scale intentionnel)
func _update_campeur(campeur_id: String, game_delta: float) -> void:
	if not GameData.campeurs.has(campeur_id):
		return
	var data: CampeurData = GameData.campeurs[campeur_id]
	for besoin_id in data.besoins:
		var besoin: BesoinData = data.besoins[besoin_id]
		besoin.valeur_actuelle = maxf(0.0, besoin.valeur_actuelle - besoin.taux_decay * besoin.modificateur_decay * game_delta)
		_check_etat_critique(campeur_id, besoin)
	# Tick AI (S2.5)
	if not _state_machines.has(campeur_id):
		return
	var sm: StateMachine = _state_machines[campeur_id]
	sm.timer += game_delta
	match sm.etat:
		StateMachine.Etat.IDLE:
			if sm.timer >= StateMachine.DECISION_INTERVAL:
				_evaluer_et_agir(campeur_id)
		StateMachine.Etat.WALKING:
			if sm.timer >= StateMachine.MAX_WALK_TIME:
				sm.transition_vers(StateMachine.Etat.IDLE)
		StateMachine.Etat.ATTENDING:
			pass  # Transitoire instantané — géré dans _on_destination_atteinte


func _evaluer_et_agir(campeur_id: String) -> void:
	if not _state_machines.has(campeur_id):
		return
	var besoin := get_besoin_prioritaire(campeur_id)
	var sm: StateMachine = _state_machines[campeur_id]
	if besoin == null:
		sm.timer = 0.0
		return
	var destination := _get_wander_destination()
	sm.transition_vers(StateMachine.Etat.WALKING)
	sm.besoin_cible = besoin.besoin_id
	EventBus.emit("campeur.deplacer_vers", {
		"entite_id": campeur_id,
		"position": destination,
		"besoin_id": besoin.besoin_id,
		"timestamp": _elapsed_game_time,
	})


func _on_destination_atteinte(payload: Dictionary) -> void:
	var campeur_id: String = payload.get("entite_id", "")
	if not _state_machines.has(campeur_id):
		return
	var sm: StateMachine = _state_machines[campeur_id]
	if sm.etat != StateMachine.Etat.WALKING:
		return
	sm.transition_vers(StateMachine.Etat.ATTENDING)
	if sm.besoin_cible != "":
		satisfaire_besoin(campeur_id, sm.besoin_cible, StateMachine.SATISFACTION_QUANTITE)
	sm.transition_vers(StateMachine.Etat.IDLE)


func _get_wander_destination() -> Vector2:
	var cell_x := floorf(randf_range(1.0, float(GridSystem.MAP_CELLS - 1)))
	var cell_y := floorf(randf_range(1.0, float(GridSystem.MAP_CELLS - 1)))
	return GridSystem.grid_to_world(Vector2i(int(cell_x), int(cell_y)))


func _check_etat_critique(campeur_id: String, besoin: BesoinData) -> void:
	if not _critique_notified.has(campeur_id):
		return
	var notifies: Array = _critique_notified[campeur_id]
	if besoin.valeur_actuelle < besoin.seuil_critique:
		if besoin.besoin_id not in notifies:
			notifies.append(besoin.besoin_id)
			EventBus.emit("besoin.critique", {
				"entite_id": campeur_id,
				"besoin_id": besoin.besoin_id,
				"niveau": besoin.niveau,
				"timestamp": _elapsed_game_time,
			})
	else:
		# Besoin récupéré — réinitialiser pour la prochaine transition critique
		notifies.erase(besoin.besoin_id)


func get_besoin_prioritaire(campeur_id: String) -> BesoinData:
	if not GameData.campeurs.has(campeur_id):
		push_error("NeedsSystem.get_besoin_prioritaire: campeur introuvable — " + campeur_id)
		return null
	var data: CampeurData = GameData.campeurs[campeur_id]
	_prio_primaires.clear()
	_prio_secondaires.clear()
	_prio_tertiaires.clear()

	for besoin_id in data.besoins:
		var besoin: BesoinData = data.besoins[besoin_id]
		if besoin.valeur_actuelle >= besoin.seuil_satisfait:
			continue  # Ignoré — satisfait
		match besoin.niveau:
			"primaire":   _prio_primaires.append(besoin)
			"secondaire": _prio_secondaires.append(besoin)
			"tertiaire":  _prio_tertiaires.append(besoin)
			_: push_warning("NeedsSystem.get_besoin_prioritaire: niveau inconnu '%s' pour besoin '%s'" % [besoin.niveau, besoin.besoin_id])

	# Chercher dans l'ordre de priorité, retourner le plus urgent (valeur la plus basse)
	for groupe in [_prio_primaires, _prio_secondaires, _prio_tertiaires]:
		if groupe.is_empty():
			continue
		groupe.sort_custom(func(a: BesoinData, b: BesoinData) -> bool:
			var score_a := (1.0 - a.valeur_actuelle) * a.modificateur_decay
			var score_b := (1.0 - b.valeur_actuelle) * b.modificateur_decay
			return score_a > score_b  # Plus haut score = plus urgent
		)
		return groupe[0]

	return null  # Tous les besoins sont satisfaits


func satisfaire_besoin(campeur_id: String, besoin_id: String, quantite: float) -> void:
	if not GameData.campeurs.has(campeur_id):
		push_error("NeedsSystem.satisfaire_besoin: campeur introuvable — " + campeur_id)
		return
	var data: CampeurData = GameData.campeurs[campeur_id]
	if not data.besoins.has(besoin_id):
		push_error("NeedsSystem.satisfaire_besoin: besoin introuvable — " + besoin_id + " pour " + campeur_id)
		return
	var besoin: BesoinData = data.besoins[besoin_id]
	besoin.valeur_actuelle = clampf(besoin.valeur_actuelle + quantite, 0.0, 1.0)


# LOD comportemental — connecté au système de caméra en S2.4/S2.5
# Appeler avec lod_factor < 1.0 pour les campeurs hors viewport
# Exemple : set_campeur_lod("c_001", 0.25) → mise à jour 4x moins fréquente (simulée via delta réduit)
func set_campeur_lod(campeur_id: String, lod_factor: float) -> void:
	# Stub — implémentation complète quand la caméra peut signaler les campeurs hors viewport
	# La valeur est stockée mais pas encore utilisée dans _update_campeur
	if not campeur_id in _registered_campeurs:
		return
	_lod_factors[campeur_id] = clampf(lod_factor, 0.1, 1.0)
