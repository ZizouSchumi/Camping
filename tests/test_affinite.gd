extends GutTest

# Tests unitaires — Story 4.2 : Interactions sociales, score d'affinité
# AC #7 : au moins 6 tests GUT

func after_each() -> void:
	GameData.affinites.clear()


# AC #1 — AffiniteData : valeurs par défaut
func test_affinite_data_defaults() -> void:
	var a := AffiniteData.new()
	assert_eq(a.score, 0.5, "score par défaut = 0.5")
	assert_eq(a.nb_rencontres, 0, "nb_rencontres par défaut = 0")
	assert_eq(a.campeur_a_id, "", "campeur_a_id vide par défaut")
	assert_eq(a.campeur_b_id, "", "campeur_b_id vide par défaut")


# AC #2 — clé d'affinité symétrique (a↔b = b↔a)
func test_get_affinite_key_symetrique() -> void:
	var key_ab := GameData.get_affinite_key("c_001", "c_002")
	var key_ba := GameData.get_affinite_key("c_002", "c_001")
	assert_eq(key_ab, key_ba, "La clé est la même peu importe l'ordre")
	assert_eq(key_ab, "c_001|c_002", "Format attendu : id_min|id_max")


# AC #4 — axes identiques (défaut 0.5) → compatibilité = 1.0
func test_calculer_compatibilite_axes_identiques() -> void:
	var pers_a := PersonnaliteData.new()
	var pers_b := PersonnaliteData.new()
	var compat := NeedsSystem._calculer_compatibilite(pers_a, pers_b)
	assert_almost_eq(compat, 1.0, 0.001, "Personnalités identiques → compatibilité maximale")


# AC #4 — axes opposés (0.0 vs 1.0) → compatibilité = 0.0
func test_calculer_compatibilite_axes_opposes() -> void:
	var pers_a := PersonnaliteData.new()
	pers_a.sociabilite = 0.0
	pers_a.vitalite = 0.0
	pers_a.appetit = 0.0
	pers_a.exigence = 0.0
	pers_a.zenitude = 0.0
	var pers_b := PersonnaliteData.new()
	pers_b.sociabilite = 1.0
	pers_b.vitalite = 1.0
	pers_b.appetit = 1.0
	pers_b.exigence = 1.0
	pers_b.zenitude = 1.0
	var compat := NeedsSystem._calculer_compatibilite(pers_a, pers_b)
	assert_almost_eq(compat, 0.0, 0.001, "Personnalités opposées → compatibilité nulle")


# AC #4 — axes à mi-distance (0.0 vs 0.5) → compatibilité = 0.5
func test_calculer_compatibilite_axes_neutres() -> void:
	var pers_a := PersonnaliteData.new()
	pers_a.sociabilite = 0.0
	pers_a.vitalite = 0.0
	pers_a.appetit = 0.0
	pers_a.exigence = 0.0
	pers_a.zenitude = 0.0
	var pers_b := PersonnaliteData.new()
	# pers_b garde les valeurs par défaut (0.5 sur tous les axes)
	var compat := NeedsSystem._calculer_compatibilite(pers_a, pers_b)
	assert_almost_eq(compat, 0.5, 0.001, "Demi-distance sur chaque axe → compatibilité neutre")


# AC #4, #5 — première rencontre crée AffiniteData, deuxième met à jour le score
func test_gerer_rencontre_cree_et_met_a_jour_affinite() -> void:
	var id_a := "c_test_r_001"
	var id_b := "c_test_r_002"
	var key := GameData.get_affinite_key(id_a, id_b)

	# Setup campeurs sans personnalite → score initial = 0.5 (valeur neutre)
	var data_a := CampeurData.new()
	data_a.campeur_id = id_a
	data_a.prenom = "RA"
	GameData.campeurs[id_a] = data_a
	var data_b := CampeurData.new()
	data_b.campeur_id = id_b
	data_b.prenom = "RB"
	GameData.campeurs[id_b] = data_b

	# Première rencontre
	NeedsSystem._gerer_rencontre(id_a, id_b)
	assert_true(GameData.affinites.has(key), "AffiniteData créée après première rencontre")
	var affinite: AffiniteData = GameData.affinites[key]
	assert_eq(affinite.nb_rencontres, 1, "nb_rencontres = 1 après première rencontre")
	assert_almost_eq(affinite.score, 0.5, 0.001, "score initial = 0.5 (personnalite null)")

	# Deuxième rencontre (score >= 0.5 → +0.05)
	var score_avant := affinite.score
	NeedsSystem._gerer_rencontre(id_a, id_b)
	assert_eq(affinite.nb_rencontres, 2, "nb_rencontres = 2 après deuxième rencontre")
	assert_gt(affinite.score, score_avant, "score augmente si compatibles (>= 0.5)")

	# Deuxième rencontre avec score < 0.5 → score diminue (-0.03)
	var affinite_incompat := AffiniteData.new()
	affinite_incompat.score = 0.3
	var key_incompat := GameData.get_affinite_key(id_a, "c_test_r_003")
	GameData.affinites[key_incompat] = affinite_incompat
	var score_incompat_avant := affinite_incompat.score
	var data_c := CampeurData.new()
	data_c.campeur_id = "c_test_r_003"
	data_c.prenom = "RC"
	GameData.campeurs["c_test_r_003"] = data_c
	NeedsSystem._gerer_rencontre(id_a, "c_test_r_003")
	assert_lt(affinite_incompat.score, score_incompat_avant, "score diminue si incompatibles (< 0.5)")

	# Nettoyage
	GameData.campeurs.erase(id_a)
	GameData.campeurs.erase(id_b)
	GameData.campeurs.erase("c_test_r_003")
