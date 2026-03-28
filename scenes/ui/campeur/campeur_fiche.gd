class_name CampeurFiche extends PanelContainer

# scenes/ui/campeur/campeur_fiche.gd
# Panneau fiche campeur — ouvert via UIManager.open("campeur_fiche", {"campeur_id": id})
# Lecture seule : jamais de modification directe des données — UI read-only

var _label_prenom: Label
var _label_age: Label
var _label_genre: Label
var _label_sejour: Label
var _besoins_container: VBoxContainer
var _section_personnalite: VBoxContainer
var _axe_labels: Dictionary = {}  # axe_id → Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	custom_minimum_size = Vector2(320.0, 500.0)

	var margin := MarginContainer.new()
	for side: String in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(304.0, 484.0)
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# ── Bouton Fermer ──
	var btn := Button.new()
	btn.text = "✕ Fermer"
	btn.pressed.connect(func() -> void: UIManager.close("campeur_fiche"))
	vbox.add_child(btn)

	# ── Header : portrait + identité ──
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var portrait := _make_placeholder("Portrait\n(S2.7)", Vector2(64.0, 64.0))
	header.add_child(portrait)

	var identite := VBoxContainer.new()
	identite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identite)

	_label_prenom = Label.new()
	_label_prenom.name = "LabelPrenom"
	identite.add_child(_label_prenom)

	_label_age = Label.new()
	identite.add_child(_label_age)

	_label_genre = Label.new()
	identite.add_child(_label_genre)

	_label_sejour = Label.new()
	identite.add_child(_label_sejour)

	# ── Section Besoins ──
	var titre_besoins := Label.new()
	titre_besoins.text = "─ Besoins ─"
	vbox.add_child(titre_besoins)

	_besoins_container = VBoxContainer.new()
	vbox.add_child(_besoins_container)

	# ── Section Personnalité ──
	_section_personnalite = VBoxContainer.new()
	vbox.add_child(_section_personnalite)

	var titre_perso := Label.new()
	titre_perso.text = "─ Personnalité ─"
	_section_personnalite.add_child(titre_perso)

	for axe_id: String in ["sociabilite", "vitalite", "appetit", "exigence", "zenitude"]:
		var lbl := Label.new()
		lbl.name = "Axe_" + axe_id
		_section_personnalite.add_child(lbl)
		_axe_labels[axe_id] = lbl

	# ── Placeholders enrichissement progressif ──
	vbox.add_child(_make_placeholder("Emotes flottantes (S2.8)", Vector2(0.0, 40.0)))
	vbox.add_child(_make_placeholder("Journal de séjour (E05)", Vector2(0.0, 40.0)))


func _make_placeholder(text: String, min_size: Vector2 = Vector2(0.0, 40.0)) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = min_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.78, 0.78, 0.78)
	panel.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(lbl)
	return panel


func initialize(campeur_id: String) -> void:
	if not GameData.campeurs.has(campeur_id):
		push_error("CampeurFiche.initialize: campeur_id introuvable — " + campeur_id)
		return
	var data: CampeurData = GameData.campeurs[campeur_id]
	_fill_identite(data)
	_fill_besoins(data)
	_fill_personnalite(data)


func _fill_identite(data: CampeurData) -> void:
	_label_prenom.text = data.prenom
	_label_age.text = str(data.age) + " ans"
	_label_genre.text = data.genre
	var duree := data.date_depart_prevue - data.date_arrivee
	if duree <= 0.0:
		_label_sejour.text = "Durée inconnue"
	else:
		_label_sejour.text = str(ceili(duree)) + " jour(s)"


func _fill_besoins(data: CampeurData) -> void:
	for child in _besoins_container.get_children():
		child.queue_free()

	var labels_niveaux: Dictionary = {"primaire": "Primaires", "secondaire": "Secondaires", "tertiaire": "Tertiaires"}
	for niveau: String in ["primaire", "secondaire", "tertiaire"]:
		var titre := Label.new()
		titre.text = labels_niveaux[niveau]
		titre.add_theme_font_size_override("font_size", 11)
		_besoins_container.add_child(titre)
		for besoin_id: String in data.besoins:
			var besoin: BesoinData = data.besoins[besoin_id]
			if besoin.niveau != niveau:
				continue
			var pct := int(round(besoin.valeur_actuelle * 100.0))
			var ligne := Label.new()
			ligne.text = besoin_id + " : " + str(pct) + " % (" + besoin.get_etat() + ")"
			_besoins_container.add_child(ligne)


func _fill_personnalite(data: CampeurData) -> void:
	if data.personnalite == null:
		_section_personnalite.visible = false
		return
	_section_personnalite.visible = true
	var noms: Dictionary = {
		"sociabilite": "Sociabilité",
		"vitalite": "Vitalité",
		"appetit": "Appétit",
		"exigence": "Exigence",
		"zenitude": "Zénitude",
	}
	for axe_id: String in _axe_labels:
		var val := data.personnalite.get_axe(axe_id)
		var pct := int(round(val * 100.0))
		(_axe_labels[axe_id] as Label).text = noms.get(axe_id, axe_id) + " : " + str(pct) + " %"
