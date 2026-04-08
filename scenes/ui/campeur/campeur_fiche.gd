class_name CampeurFiche extends PanelContainer

# scenes/ui/campeur/campeur_fiche.gd
const _EmoteDisplay := preload("res://scenes/campeurs/emote_display.gd")
# Panneau fiche campeur — ouvert via UIManager.open("campeur_fiche", {"campeur_id": id})
# Lecture seule : jamais de modification directe des données — UI read-only

var _campeur_id: String = ""

# Section identité
var _label_prenom: Label
var _label_age: Label
var _label_genre: Label
var _label_sejour: Label
var _portrait_rect: TextureRect

# Section humeur globale (S4.6)
var _humeur_bar: ProgressBar
var _humeur_label: Label
var _humeur_stylebox: StyleBoxFlat  # Réutilisé entre refreshs pour éviter allocs continues

# Section besoins
var _besoins_container: VBoxContainer

# Section personnalité
var _section_personnalite: VBoxContainer
var _axe_labels: Dictionary = {}  # axe_id → Label

# Section état émotionnel
var _emote_label: Label

# Section infos supplémentaires (S4.6)
var _label_emplacement: Label
var _label_satisfaction: Label
var _label_note_prevision: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	custom_minimum_size = Vector2(320.0, 520.0)

	var margin := MarginContainer.new()
	for side: String in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(304.0, 504.0)
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

	_portrait_rect = TextureRect.new()
	_portrait_rect.custom_minimum_size = Vector2(64.0, 64.0)
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_portrait_rect)

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

	# ── Section Humeur globale (S4.6) ──
	var titre_humeur := Label.new()
	titre_humeur.text = "─ Humeur ─"
	vbox.add_child(titre_humeur)

	var humeur_row := HBoxContainer.new()
	vbox.add_child(humeur_row)

	_humeur_bar = ProgressBar.new()
	_humeur_bar.custom_minimum_size = Vector2(120.0, 18.0)
	_humeur_bar.min_value = 0.0
	_humeur_bar.max_value = 1.0
	_humeur_bar.show_percentage = false
	_humeur_stylebox = StyleBoxFlat.new()
	_humeur_bar.add_theme_stylebox_override("fill", _humeur_stylebox)
	humeur_row.add_child(_humeur_bar)

	_humeur_label = Label.new()
	_humeur_label.text = " Humeur : ☆☆☆☆☆"
	humeur_row.add_child(_humeur_label)

	# ── Infos séjour supplémentaires (S4.6) ──
	_label_emplacement = _add_label(vbox, "Emplacement : —")
	_label_satisfaction = _add_label(vbox, "Satisfaction : —")
	_label_note_prevision = _add_label(vbox, "Note prévisionnelle : —")

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

	# ── Section État émotionnel (S2.8) ──
	var emote_section := VBoxContainer.new()
	var titre_emote := Label.new()
	titre_emote.text = "─ État émotionnel ─"
	emote_section.add_child(titre_emote)
	_emote_label = Label.new()
	_emote_label.name = "EmoteLabel"
	_emote_label.text = "—"
	emote_section.add_child(_emote_label)
	vbox.add_child(emote_section)

	# ── Placeholders enrichissement progressif ──
	vbox.add_child(_make_placeholder("Journal de séjour (E05)", Vector2(0.0, 40.0)))

	# ── Timer de refresh automatique (S4.6) ──
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_refresh)
	add_child(timer)


func _add_label(parent: Control, text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	parent.add_child(lbl)
	return lbl


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


func initialize(panel_data: Dictionary) -> void:
	_campeur_id = panel_data.get("campeur_id", "")
	if not GameData.campeurs.has(_campeur_id):
		push_error("CampeurFiche.initialize: campeur_id introuvable — " + _campeur_id)
		return
	var data: CampeurData = GameData.campeurs[_campeur_id]
	if _portrait_rect != null:
		_portrait_rect.texture = _generate_portrait(data)
	_fill_identite(data)
	_fill_personnalite(data)
	_fill_emote(data)
	_refresh()
	EventBus.subscribe("campeur.depart_avec_avis", _on_depart)
	EventBus.subscribe("besoin.critique", _on_besoin_critique)


func _exit_tree() -> void:
	EventBus.unsubscribe("campeur.depart_avec_avis", _on_depart)
	EventBus.unsubscribe("besoin.critique", _on_besoin_critique)


func _on_depart(payload: Dictionary) -> void:
	if _campeur_id != "" and payload.get("entite_id", "") == _campeur_id:
		UIManager.close("campeur_fiche")


func _on_besoin_critique(payload: Dictionary) -> void:
	if payload.get("entite_id", "") == _campeur_id:
		_refresh()


func _refresh() -> void:
	if _campeur_id == "" or not GameData.campeurs.has(_campeur_id):
		return
	var data: CampeurData = GameData.campeurs[_campeur_id]
	_fill_besoins(data)
	var humeur := _calculer_humeur(data)
	_humeur_bar.value = humeur
	var etat_humeur := "satisfait" if humeur >= 0.7 else ("moyen" if humeur >= 0.4 else "critique")
	_apply_humeur_color(etat_humeur)
	_humeur_label.text = " Humeur : " + _humeur_en_etoiles(humeur)
	var eid := data.emplacement_id
	_label_emplacement.text = "Emplacement : " + (eid if eid != "" else "Aucun")
	_label_satisfaction.text = "Satisfaction : %d%%" % int(data.satisfaction_moyenne * 100.0)
	var exigence := data.personnalite.exigence if data.personnalite != null else 0.5
	_label_note_prevision.text = "Note prévisionnelle : %d/5" % NeedsSystem._calculer_note(
		data.satisfaction_moyenne, exigence
	)


func _calculer_humeur(data: CampeurData) -> float:
	if data.besoins.is_empty():
		return 0.5
	const POIDS: Dictionary = {"primaire": 1.0, "secondaire": 0.6, "tertiaire": 0.3}
	var somme_ponderee := 0.0
	var poids_total := 0.0
	for besoin_id: String in data.besoins:
		var besoin: BesoinData = data.besoins[besoin_id]
		var poids: float = POIDS.get(besoin.niveau, 0.3)
		somme_ponderee += besoin.valeur_actuelle * poids
		poids_total += poids
	if poids_total == 0.0:
		return 0.5
	return somme_ponderee / poids_total


func _humeur_en_etoiles(humeur: float) -> String:
	var etoiles := clampi(int(round(humeur * 5.0)), 1, 5)
	return "★".repeat(etoiles) + "☆".repeat(5 - etoiles)


func _apply_humeur_color(etat: String) -> void:
	_humeur_stylebox.bg_color = _color_for_etat(etat)


func _color_for_etat(etat: String) -> Color:
	match etat:
		"satisfait": return Color(0.20, 0.72, 0.30)  # vert
		"moyen":     return Color(0.95, 0.80, 0.15)  # jaune
		"eleve":     return Color(0.95, 0.50, 0.10)  # orange
		"critique":  return Color(0.85, 0.15, 0.10)  # rouge
	return Color(0.55, 0.55, 0.55)  # gris


func _apply_bar_color(bar: ProgressBar, etat: String) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = _color_for_etat(etat)
	bar.add_theme_stylebox_override("fill", style)


func _generate_portrait(data: CampeurData) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var color: Color
	match data.genre:
		"homme":
			color = Color(0.29, 0.565, 0.855)
		"femme":
			color = Color(0.855, 0.29, 0.478)
		_:
			color = Color(0.29, 0.855, 0.478)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _fill_identite(data: CampeurData) -> void:
	_label_prenom.text = data.prenom
	_label_age.text = str(data.age) + " ans"
	_label_genre.text = data.genre
	var duree := data.date_depart_prevue - data.date_arrivee
	if duree <= 0.0:
		_label_sejour.text = "Durée inconnue"
	else:
		var jours := ceili(duree / SeasonManager.SECONDS_PER_DAY)
		_label_sejour.text = str(jours) + " jour(s)"


func _fill_besoins(data: CampeurData) -> void:
	for child in _besoins_container.get_children():
		child.queue_free()

	const LABELS_NIVEAUX: Dictionary = {"primaire": "Primaires", "secondaire": "Secondaires", "tertiaire": "Tertiaires"}
	for niveau: String in ["primaire", "secondaire", "tertiaire"]:
		# Collecter d'abord les besoins du niveau — n'afficher le titre que s'il y en a
		var besoins_du_niveau: Array[BesoinData] = []
		var ids_du_niveau: Array[String] = []
		for besoin_id: String in data.besoins:
			var besoin: BesoinData = data.besoins[besoin_id]
			if besoin.niveau == niveau:
				besoins_du_niveau.append(besoin)
				ids_du_niveau.append(besoin_id)
		if besoins_du_niveau.is_empty():
			continue

		var titre := Label.new()
		titre.text = LABELS_NIVEAUX[niveau]
		titre.add_theme_font_size_override("font_size", 11)
		_besoins_container.add_child(titre)

		for i: int in range(besoins_du_niveau.size()):
			var besoin: BesoinData = besoins_du_niveau[i]
			var besoin_id: String = ids_du_niveau[i]

			var row := HBoxContainer.new()
			_besoins_container.add_child(row)

			var bar := ProgressBar.new()
			bar.custom_minimum_size = Vector2(80.0, 14.0)
			bar.min_value = 0.0
			bar.max_value = 1.0
			bar.value = besoin.valeur_actuelle
			bar.show_percentage = false
			_apply_bar_color(bar, besoin.get_etat())
			row.add_child(bar)

			var lbl := Label.new()
			lbl.text = " " + besoin_id + " (" + besoin.get_etat() + ")"
			lbl.add_theme_font_size_override("font_size", 11)
			row.add_child(lbl)


func _fill_emote(data: CampeurData) -> void:
	var besoin: BesoinData = NeedsSystem.get_besoin_prioritaire(data.campeur_id)
	if besoin == null:
		_emote_label.text = "✅ Tous les besoins satisfaits"
		return
	var emoji: String = _EmoteDisplay.EMOTES.get(besoin.besoin_id, "❓")
	_emote_label.text = emoji + " " + besoin.besoin_id + " (" + besoin.get_etat() + ")"


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
