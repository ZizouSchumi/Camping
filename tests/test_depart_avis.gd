extends GutTest

# Tests pour S4.5 — Système de départ et avis
# AC9 : 5 tests minimum

# AC9a — Note 5 pour satisfaction élevée
func test_note_5_pour_satisfaction_elevee() -> void:
	var note := NeedsSystem._calculer_note(0.9, 0.5)
	assert_eq(note, 5, "satisfaction 0.9 avec exigence 0.5 → 5 étoiles")


# AC9b — Note 1 pour satisfaction basse
func test_note_1_pour_satisfaction_basse() -> void:
	var note := NeedsSystem._calculer_note(0.1, 0.5)
	assert_eq(note, 1, "satisfaction 0.1 → 1 étoile")


# AC9c — Exigence élevée réduit la note d'un cran
func test_exigence_elevee_reduit_la_note() -> void:
	var note_normal := NeedsSystem._calculer_note(0.85, 0.5)   # → 5
	var note_exigeant := NeedsSystem._calculer_note(0.85, 0.75) # → 4 (malus)
	assert_lt(note_exigeant, note_normal,
		"Un campeur exigeant (>=0.7) doit avoir une note inférieure pour la même satisfaction")


# AC9d — Commentaire non vide pour toutes les notes
func test_commentaire_non_vide() -> void:
	for note in [1, 2, 3, 4, 5]:
		var commentaire := NeedsSystem._generer_commentaire(note)
		assert_ne(commentaire, "", "Commentaire non vide pour note " + str(note))


# AC9e — Avis ajouté dans GameData
func test_avis_ajoute_dans_gamedata() -> void:
	var avant := GameData.avis.size()
	GameData.ajouter_avis({"note": 4, "commentaire": "Test", "campeur_id": "c_test_avis"})
	assert_eq(GameData.avis.size(), avant + 1, "Un avis doit être ajouté dans GameData.avis")
	GameData.avis.pop_back()  # Cleanup


# AC9e bis — FIFO : nombre max d'avis respecté, les plus anciens sont éjectés
func test_max_avis_lifo() -> void:
	# Snapshot des avis existants pour restauration propre après le test
	var snapshot := GameData.avis.duplicate()
	GameData.avis.clear()
	for i in range(GameData.MAX_AVIS + 5):
		GameData.ajouter_avis({"note": 3, "commentaire": "Flood", "campeur_id": "c_lifo_%d" % i})
	assert_lte(GameData.avis.size(), GameData.MAX_AVIS,
		"GameData.avis ne doit pas dépasser MAX_AVIS entrées")
	# Vérifier que les plus récents sont conservés (FIFO — les anciens sont éjectés)
	assert_eq((GameData.avis.back() as Dictionary).get("campeur_id"), "c_lifo_%d" % (GameData.MAX_AVIS + 4),
		"Le dernier avis ajouté doit être présent")
	# Restauration
	GameData.avis = snapshot
