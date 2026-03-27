extends GutTest

# Tests unitaires pour le système de personnalité (Story 2.3)
# Couvre PersonnaliteData, NeedsSystem._initialiser_personnalite,
# _appliquer_poids_personnalite, et l'impact sur get_besoin_prioritaire.

const ID_A: String = "c_perso_001"
const ID_B: String = "c_perso_002"


func _creer_campeur(campeur_id: String) -> void:
	var data := CampeurData.new()
	data.campeur_id = campeur_id
	data.prenom = "TestPerso"
	GameData.campeurs[campeur_id] = data
	NeedsSystem.register_campeur(campeur_id)


func _nettoyer_campeur(campeur_id: String) -> void:
	NeedsSystem.unregister_campeur(campeur_id)
	GameData.campeurs.erase(campeur_id)


func before_each() -> void:
	_creer_campeur(ID_A)


func after_each() -> void:
	_nettoyer_campeur(ID_A)
	if GameData.campeurs.has(ID_B):
		_nettoyer_campeur(ID_B)


# AC8a — après register, personnalite != null et tous les axes dans [0.0, 1.0]
func test_personnalite_assignee_au_register() -> void:
	var data: CampeurData = GameData.campeurs[ID_A]
	assert_not_null(data.personnalite, "Personnalité assignée après register_campeur")
	assert_between(data.personnalite.sociabilite, 0.0, 1.0, "sociabilite dans [0.0, 1.0]")
	assert_between(data.personnalite.vitalite,    0.0, 1.0, "vitalite dans [0.0, 1.0]")
	assert_between(data.personnalite.appetit,     0.0, 1.0, "appetit dans [0.0, 1.0]")
	assert_between(data.personnalite.exigence,    0.0, 1.0, "exigence dans [0.0, 1.0]")
	assert_between(data.personnalite.zenitude,    0.0, 1.0, "zenitude dans [0.0, 1.0]")


# AC8b — socialiser.modificateur_decay > 1.0 quand sociabilite = 1.0
func test_modificateur_decay_applique_selon_axe() -> void:
	var p := PersonnaliteData.new()
	p.sociabilite = 1.0
	p.vitalite    = 0.5
	p.appetit     = 0.5
	p.exigence    = 0.5
	p.zenitude    = 0.5
	NeedsSystem.initialiser_personnalite(ID_A, p)
	var data: CampeurData = GameData.campeurs[ID_A]
	assert_gt(data.besoins["socialiser"].modificateur_decay, 1.0,
		"socialiser.modificateur_decay > 1.0 quand sociabilite=1.0")


# AC8c — deux campeurs, primaires satisfaits, socialiser=divertissement=0.4
#         campeur A (sociabilite=1.0) → socialiser prioritaire
#         campeur B (sociabilite=0.0) → divertissement prioritaire
func test_personnalite_affecte_priorite_secondaire() -> void:
	_creer_campeur(ID_B)

	# Personnalite A : très sociable, vitalite neutre
	var p_a := PersonnaliteData.new()
	p_a.sociabilite = 1.0
	p_a.vitalite    = 0.5
	p_a.appetit     = 0.5
	p_a.exigence    = 0.5
	p_a.zenitude    = 0.5
	NeedsSystem.initialiser_personnalite(ID_A, p_a)

	# Personnalite B : solitaire, vitalite neutre
	var p_b := PersonnaliteData.new()
	p_b.sociabilite = 0.0
	p_b.vitalite    = 0.5
	p_b.appetit     = 0.5
	p_b.exigence    = 0.5
	p_b.zenitude    = 0.5
	NeedsSystem.initialiser_personnalite(ID_B, p_b)

	# Vérifier les pré-conditions : les modificateurs doivent être dans les valeurs attendues
	# pour que le test soit déterministe (dépend de la config JSON poids_besoins)
	var d_a_pre: CampeurData = GameData.campeurs[ID_A]
	var d_b_pre: CampeurData = GameData.campeurs[ID_B]
	assert_almost_eq(d_a_pre.besoins["socialiser"].modificateur_decay, 1.8, 0.001,
		"Campeur A : socialiser.modificateur_decay = lerp(0.2, 1.8, 1.0) = 1.8")
	assert_almost_eq(d_b_pre.besoins["socialiser"].modificateur_decay, 0.2, 0.001,
		"Campeur B : socialiser.modificateur_decay = lerp(0.2, 1.8, 0.0) = 0.2")
	assert_almost_eq(d_a_pre.besoins["divertissement"].modificateur_decay, 1.0, 0.001,
		"divertissement neutre pour campeur A (vitalite=0.5)")
	assert_almost_eq(d_b_pre.besoins["divertissement"].modificateur_decay, 1.0, 0.001,
		"divertissement neutre pour campeur B (vitalite=0.5)")

	# Satisfaire tous les besoins puis abaisser exactement socialiser et divertissement
	for cid in [ID_A, ID_B]:
		var d: CampeurData = GameData.campeurs[cid]
		for bid in d.besoins:
			d.besoins[bid].valeur_actuelle = 1.0
		d.besoins["socialiser"].valeur_actuelle     = 0.4
		d.besoins["divertissement"].valeur_actuelle = 0.4

	var prio_a: BesoinData = NeedsSystem.get_besoin_prioritaire(ID_A)
	var prio_b: BesoinData = NeedsSystem.get_besoin_prioritaire(ID_B)

	assert_not_null(prio_a, "Campeur A a un besoin prioritaire")
	assert_not_null(prio_b, "Campeur B a un besoin prioritaire")
	assert_eq(prio_a.besoin_id, "socialiser",
		"Campeur A (sociabilite=1.0) priorise socialiser")
	assert_eq(prio_b.besoin_id, "divertissement",
		"Campeur B (sociabilite=0.0) priorise divertissement")


# AC8d — hiérarchie non brisée : primaire (faible modificateur) reste prioritaire sur secondaire (fort modificateur)
func test_hierarchie_non_brisee_par_personnalite() -> void:
	var data: CampeurData = GameData.campeurs[ID_A]
	# Satisfaire tout à 1.0
	for bid in data.besoins:
		data.besoins[bid].valeur_actuelle = 1.0
	# Primaire faim à 0.4, avec un faible modificateur_decay = 0.3
	data.besoins["faim"].valeur_actuelle   = 0.4
	data.besoins["faim"].modificateur_decay = 0.3
	# score_faim = (1-0.4) * 0.3 = 0.18
	# Secondaire socialiser à 0.1, avec un fort modificateur_decay = 2.0
	data.besoins["socialiser"].valeur_actuelle   = 0.1
	data.besoins["socialiser"].modificateur_decay = 2.0
	# score_socialiser = (1-0.1) * 2.0 = 1.8

	var prio: BesoinData = NeedsSystem.get_besoin_prioritaire(ID_A)
	assert_not_null(prio, "Un besoin prioritaire trouvé")
	assert_eq(prio.besoin_id, "faim",
		"faim (primaire, faible modificateur) reste prioritaire sur socialiser (secondaire, fort modificateur)")


# AC8e — initialiser_personnalite() avec personnalite custom assigne bien la référence
func test_initialiser_personnalite_explicite() -> void:
	var p := PersonnaliteData.new()
	p.sociabilite = 0.3
	p.vitalite    = 0.7
	p.appetit     = 0.2
	p.exigence    = 0.9
	p.zenitude    = 0.1
	NeedsSystem.initialiser_personnalite(ID_A, p)
	var data: CampeurData = GameData.campeurs[ID_A]
	assert_eq(data.personnalite, p, "La personnalité custom est bien assignée")


# AC8e — initialiser_personnalite met à jour les modificateurs après assignment
func test_initialiser_personnalite_met_a_jour_modificateurs() -> void:
	var p := PersonnaliteData.new()
	p.sociabilite = 1.0
	p.vitalite    = 0.5
	p.appetit     = 0.5
	p.exigence    = 0.5
	p.zenitude    = 0.5
	NeedsSystem.initialiser_personnalite(ID_A, p)
	var data: CampeurData = GameData.campeurs[ID_A]
	# socialiser : lerp(0.2, 1.8, 1.0) = 1.8
	assert_almost_eq(data.besoins["socialiser"].modificateur_decay, 1.8, 0.001,
		"socialiser.modificateur_decay = 1.8 après initialiser_personnalite avec sociabilite=1.0")


# Comportement neutre : tous axes à 0.5 → tous modificateur_decay ≈ 1.0
func test_comportement_neutre_axe_0_5() -> void:
	var p := PersonnaliteData.new()
	# Tous les axes sont à 0.5 par défaut dans PersonnaliteData
	NeedsSystem.initialiser_personnalite(ID_A, p)
	var data: CampeurData = GameData.campeurs[ID_A]
	for bid in data.besoins:
		assert_almost_eq(data.besoins[bid].modificateur_decay, 1.0, 0.001,
			"modificateur_decay ≈ 1.0 pour " + bid + " avec axe=0.5 (comportement neutre S2.2)")


# get_axe retourne 0.5 et émet un warning pour un axe inconnu
func test_get_axe_inconnu_retourne_valeur_neutre() -> void:
	var p := PersonnaliteData.new()
	var val: float = p.get_axe("axe_inexistant_xyz")
	assert_almost_eq(val, 0.5, 0.001, "get_axe inconnu retourne 0.5 (valeur neutre)")
	assert_push_warning_count(1, "push_warning émis pour axe inconnu")
