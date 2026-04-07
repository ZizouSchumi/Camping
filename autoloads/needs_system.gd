extends Node

# NeedsSystem — boucle centralisée de mise à jour des besoins de TOUS les PNJ
# UNE seule boucle pour N campeurs — jamais de boucle individuelle par campeur
#
# CONTRAINTE ARCHITECTURALE : NeedsSystem est l'autoload #5.
# Il NE peut PAS référencer SeasonManager (autoload #6).
# La synchronisation vitesse/pause passe exclusivement par EventBus "jeu.vitesse_change".

const RAYON_PROXIMITE: float = 128.0   # 2 cellules × 64px
const COOLDOWN_RENCONTRE: float = 30.0 # secondes de jeu entre 2 rencontres pour la même paire
const DUREE_UTILISATION: float = 15.0  # secondes de jeu passées dans un bâtiment (S4.3)

# Mapping besoin_id → type_id bâtiment cible (AC #1 S4.3)
const BESOIN_BATIMENT: Dictionary = {
	"faim":              "snack",
	"soif":              "snack",
	"sommeil":           "_emplacement",  # logique spéciale — voir _trouver_emplacement_libre()
	"divertissement":    "piscine",
	"activite_physique": "piscine",
	"bien_etre":         "sanitaires",
	"accomplissement":   "",             # errance — pas de bâtiment dédié en E04
	"confort_emotionnel": "",            # errance
	"socialiser":        "",             # géré par S4.2 (proximité), pas de bâtiment
}

var _registered_campeurs: Array[String] = []
var _besoins_config: Array = []           # Chargé depuis besoins_config.json
var _personnalite_config: Dictionary = {} # Chargé depuis personnalites_config.json
var _time_scale: float = 1.0              # Synchronisé via EventBus, PAS SeasonManager
var _paused: bool = false                 # Synchronisé via EventBus, PAS SeasonManager
var _elapsed_game_time: float = 0.0       # Équivalent local de SeasonManager.current_time
var _proximite_cooldowns: Dictionary = {} # affinite_key → elapsed_game_time du dernier déclenchement
										  # TODO S3+: synchroniser depuis SaveSystem.load_game() pour éviter
										  # la désync des timestamps "besoin.critique" après rechargement de save
										  # TODO S3+: après load_game(), rappeler register_campeur() (ou
										  # initialiser_personnalite()) pour chaque campeur chargé — BesoinData.modificateur_decay
										  # n'est pas @export donc non persisté ; doit être recalculé depuis CampeurData.personnalite
var _critique_notified: Dictionary = {}   # campeur_id → Array[String] de besoin_ids en état critique
var _lod_factors: Dictionary = {}         # campeur_id → float (1.0 = full update, < 1.0 = réduit)
var _state_machines: Dictionary = {}      # campeur_id → StateMachine (S2.5)
var _utilisations_en_cours: Dictionary = {}  # campeur_id → {batiment_id, time_restant} (S4.3)
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
	if _registered_campeurs.size() >= 2:
		_verifier_proximites()


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
	_utilisations_en_cours.erase(campeur_id)
	for key in _proximite_cooldowns.keys():
		if campeur_id in key:
			_proximite_cooldowns.erase(key)


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
	_update_utilisation(campeur_id, game_delta)


func _evaluer_et_agir(campeur_id: String) -> void:
	if not _state_machines.has(campeur_id):
		return
	var besoin := get_besoin_prioritaire(campeur_id)
	var sm: StateMachine = _state_machines[campeur_id]
	if besoin == null:
		sm.timer = 0.0
		return

	var destination := Vector2.ZERO
	var batiment_id := ""
	var type_bat: String = BESOIN_BATIMENT.get(besoin.besoin_id, "")

	if type_bat == "_emplacement":
		# Logique sommeil : utiliser l'emplacement assigné ou en chercher un libre
		var campeur_data: CampeurData = GameData.campeurs[campeur_id]
		if campeur_data.emplacement_id != "":
			if GameData.batiments.has(campeur_data.emplacement_id):
				var bat: BatimentData = GameData.batiments[campeur_data.emplacement_id]
				destination = GridSystem.grid_to_world(bat.grid_pos)
				batiment_id = campeur_data.emplacement_id
			else:
				campeur_data.emplacement_id = ""  # Emplacement supprimé — réassigner
		if batiment_id == "":
			var eid := _trouver_emplacement_libre(campeur_data.world_position)
			if eid != "":
				var edata: BatimentData = GameData.batiments[eid]
				campeur_data.emplacement_id = eid
				if edata is EmplacementData:
					(edata as EmplacementData).campeur_id = campeur_id
				destination = GridSystem.grid_to_world(edata.grid_pos)
				batiment_id = eid
			else:
				destination = _get_wander_destination()

	elif type_bat != "":
		# Bâtiment standard : chercher le plus proche disponible
		var pos_campeur := GridSystem.world_to_grid(GameData.campeurs[campeur_id].world_position)
		var bat_pos := GridSystem.get_nearest(pos_campeur, type_bat)
		if bat_pos == Vector2i(-1, -1):
			destination = _get_wander_destination()  # Aucun bâtiment du type — errance
		else:
			batiment_id = _get_batiment_id_at(bat_pos)
			if batiment_id != "" and GameData.batiments.has(batiment_id):
				var bat: BatimentData = GameData.batiments[batiment_id]
				if bat.capacite_max > 0 and bat.campeurs_en_service.size() >= bat.capacite_max:
					destination = _get_wander_destination()  # File d'attente pleine — errance
					batiment_id = ""
				else:
					destination = GridSystem.grid_to_world(bat_pos)
			else:
				destination = _get_wander_destination()
	else:
		# Besoin sans bâtiment dédié (accomplissement, confort_emotionnel, socialiser) — errance
		destination = _get_wander_destination()

	sm.transition_vers(StateMachine.Etat.WALKING)
	sm.besoin_cible = besoin.besoin_id
	sm.batiment_cible = batiment_id
	EventBus.emit("campeur.deplacer_vers", {
		"entite_id": campeur_id,
		"position": destination,
		"besoin_id": besoin.besoin_id,
		"batiment_id": batiment_id,
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

	var batiment_id := sm.batiment_cible
	if batiment_id != "" and GameData.batiments.has(batiment_id):
		var bat: BatimentData = GameData.batiments[batiment_id]
		# Re-vérifier la capacité (piège #2 : deux campeurs peuvent arriver en même temps)
		if bat.capacite_max == 0 or bat.campeurs_en_service.size() < bat.capacite_max:
			bat.campeurs_en_service.append(campeur_id)
			if sm.besoin_cible != "":
				satisfaire_besoin(campeur_id, sm.besoin_cible, StateMachine.SATISFACTION_QUANTITE)
				EventBus.emit("batiment.campeur_utilise", {
					"entite_id": batiment_id,
					"campeur_id": campeur_id,
					"besoin_id": sm.besoin_cible,
					"timestamp": _elapsed_game_time,
				})
			_planifier_depart_batiment(campeur_id, batiment_id)
		else:
			# Bâtiment plein à l'arrivée — satisfaction sans bâtiment
			if sm.besoin_cible != "":
				satisfaire_besoin(campeur_id, sm.besoin_cible, StateMachine.SATISFACTION_QUANTITE)
	else:
		# Errance (pas de bâtiment cible) — satisfaction wander comme avant
		if sm.besoin_cible != "":
			satisfaire_besoin(campeur_id, sm.besoin_cible, StateMachine.SATISFACTION_QUANTITE)

	sm.transition_vers(StateMachine.Etat.IDLE)


func _planifier_depart_batiment(campeur_id: String, batiment_id: String) -> void:
	_utilisations_en_cours[campeur_id] = {
		"batiment_id": batiment_id,
		"time_restant": DUREE_UTILISATION,
	}


func _update_utilisation(campeur_id: String, game_delta: float) -> void:
	if not _utilisations_en_cours.has(campeur_id):
		return
	var util: Dictionary = _utilisations_en_cours[campeur_id]
	util["time_restant"] -= game_delta
	if util["time_restant"] <= 0.0:
		var bid: String = util["batiment_id"]
		if GameData.batiments.has(bid):
			var bat: BatimentData = GameData.batiments[bid]
			bat.campeurs_en_service.erase(campeur_id)
			if bat is EmplacementData:
				(bat as EmplacementData).campeur_id = ""
		_utilisations_en_cours.erase(campeur_id)


func _get_batiment_id_at(grid_pos: Vector2i) -> String:
	for batiment_id in GameData.batiments:
		var bat: BatimentData = GameData.batiments[batiment_id]
		if bat.grid_pos == grid_pos:
			return batiment_id
	return ""


func _trouver_emplacement_libre(world_pos: Vector2) -> String:
	var types := ["tente", "caravane", "mobil-home"]
	var meilleur_id := ""
	var meilleure_dist := 9999999.0
	for batiment_id in GameData.batiments:
		var bat: BatimentData = GameData.batiments[batiment_id]
		if bat.type_id not in types:
			continue
		if bat.capacite_max > 0 and bat.campeurs_en_service.size() >= bat.capacite_max:
			continue  # Emplacement occupé
		var bat_world := GridSystem.grid_to_world(bat.grid_pos)
		var dist := world_pos.distance_to(bat_world)
		if dist < meilleure_dist:
			meilleure_dist = dist
			meilleur_id = batiment_id
	return meilleur_id


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


# Détection pairwise de proximité — O(n²), acceptable pour n ≤ 20 campeurs (E04)
func _verifier_proximites() -> void:
	var ids := _registered_campeurs.duplicate()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var id_a: String = ids[i]
			var id_b: String = ids[j]
			if not GameData.campeurs.has(id_a) or not GameData.campeurs.has(id_b):
				continue
			var data_a: CampeurData = GameData.campeurs[id_a]
			var data_b: CampeurData = GameData.campeurs[id_b]
			if data_a.world_position.distance_to(data_b.world_position) > RAYON_PROXIMITE:
				continue
			var key := GameData.get_affinite_key(id_a, id_b)
			var last_check: float = _proximite_cooldowns.get(key, -COOLDOWN_RENCONTRE)
			if _elapsed_game_time - last_check < COOLDOWN_RENCONTRE:
				continue
			_proximite_cooldowns[key] = _elapsed_game_time
			_gerer_rencontre(id_a, id_b)


func _gerer_rencontre(id_a: String, id_b: String) -> void:
	if not GameData.campeurs.has(id_a) or not GameData.campeurs.has(id_b):
		return
	var key := GameData.get_affinite_key(id_a, id_b)
	var data_a: CampeurData = GameData.campeurs[id_a]
	var data_b: CampeurData = GameData.campeurs[id_b]
	var affinite: AffiniteData
	if not GameData.affinites.has(key):
		affinite = AffiniteData.new()
		affinite.campeur_a_id = id_a
		affinite.campeur_b_id = id_b
		affinite.score = _calculer_compatibilite(data_a.personnalite, data_b.personnalite)
		GameData.affinites[key] = affinite
	else:
		affinite = GameData.affinites[key]
		var delta_score := 0.05 if affinite.score >= 0.5 else -0.03
		affinite.score = clampf(affinite.score + delta_score, 0.0, 1.0)
	affinite.nb_rencontres += 1
	affinite.derniere_rencontre = _elapsed_game_time
	EventBus.emit("campeur.rencontre", {
		"entite_id": id_a,
		"campeur_b_id": id_b,
		"score": affinite.score,
		"nb_rencontres": affinite.nb_rencontres,
		"timestamp": _elapsed_game_time,
	})


func _calculer_compatibilite(pers_a: PersonnaliteData, pers_b: PersonnaliteData) -> float:
	if pers_a == null or pers_b == null:
		return 0.5  # Valeur neutre si personnalité non initialisée
	var axes := ["sociabilite", "vitalite", "appetit", "exigence", "zenitude"]
	var somme := 0.0
	for axe in axes:
		somme += 1.0 - absf(pers_a.get_axe(axe) - pers_b.get_axe(axe))
	return somme / float(axes.size())
