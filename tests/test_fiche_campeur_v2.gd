extends GutTest

# Tests pour S4.6 — UI fiche campeur : calculs humeur et note prévisionnelle
# Note : on teste les calculs, pas l'UI (évite d'instancier les scènes complètes)

var _fiche  # CampeurFiche — chargé dynamiquement pour éviter les problèmes de scope dans GUT
var _test_id: String = "c_fiche_test"


func before_each() -> void:
	_fiche = load("res://scenes/ui/campeur/campeur_fiche.gd").new()
	add_child(_fiche)  # déclenche _ready() → _build_ui()

	var data := CampeurData.new()
	data.campeur_id = _test_id
	data.prenom = "FicheTest"
	GameData.campeurs[_test_id] = data
	NeedsSystem.register_campeur(_test_id)


func after_each() -> void:
	NeedsSystem.unregister_campeur(_test_id)
	GameData.campeurs.erase(_test_id)
	if is_instance_valid(_fiche):
		_fiche.queue_free()


# AC7a — Les besoins primaires pèsent plus que les tertiaires dans l'humeur
func test_humeur_primaires_plus_importants() -> void:
	var data: CampeurData = GameData.campeurs[_test_id]

	# Primaires élevés (0.9) + tertiaires bas (0.1)
	for besoin_id: String in data.besoins:
		var b: BesoinData = data.besoins[besoin_id]
		b.valeur_actuelle = 0.9 if b.niveau == "primaire" else 0.1
	var humeur_prim_haute: float = _fiche._calculer_humeur(data)

	# Primaires bas (0.1) + tertiaires élevés (0.9)
	for besoin_id: String in data.besoins:
		var b: BesoinData = data.besoins[besoin_id]
		b.valeur_actuelle = 0.1 if b.niveau == "primaire" else 0.9
	var humeur_prim_basse: float = _fiche._calculer_humeur(data)

	assert_gt(humeur_prim_haute, humeur_prim_basse,
		"Primaires élevés doit donner humeur > primaires bas (pondération 1.0 > 0.3)")


# AC7a bis — Vérification numérique du calcul humeur (besoins uniformes → humeur = valeur)
func test_humeur_valeur_uniforme() -> void:
	var data: CampeurData = GameData.campeurs[_test_id]
	for besoin_id: String in data.besoins:
		data.besoins[besoin_id].valeur_actuelle = 0.6
	var humeur: float = _fiche._calculer_humeur(data)
	assert_almost_eq(humeur, 0.6, 0.001, "Tous les besoins à 0.6 → humeur = 0.6")


# AC7c — Note prévisionnelle correcte (via NeedsSystem._calculer_note)
func test_note_prevision_correcte() -> void:
	var note := NeedsSystem._calculer_note(0.85, 0.5)
	assert_eq(note, 5, "satisfaction 0.85 / exigence 0.5 → 5 étoiles")


# AC7c bis — Malus exigence sur note prévisionnelle
func test_note_avec_exigence_elevee() -> void:
	var note := NeedsSystem._calculer_note(0.85, 0.8)
	assert_eq(note, 4, "satisfaction 0.85 / exigence 0.8 (>0.7) → 4 étoiles (malus)")
