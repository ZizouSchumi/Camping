class_name DayNightOverlay extends CanvasLayer

# DayNightOverlay — overlay jour/nuit sur le monde (S4.4)
# Couleur interpolée selon l'heure : transparent le jour, bleu-nuit la nuit.
# MOUSE_FILTER_IGNORE : n'intercepte pas les clics du joueur.

var _rect: ColorRect


func _ready() -> void:
	layer = 1  # Entre le monde (0) et les panneaux UI (2)
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_update_couleur(SeasonManager.current_hour)


func _process(_delta: float) -> void:
	_update_couleur(SeasonManager.current_hour)


func _update_couleur(heure: float) -> void:
	_rect.color = _calculer_couleur(heure)


func _calculer_couleur(heure: float) -> Color:
	const COULEUR_NUIT := Color(0.05, 0.08, 0.25, 0.45)
	const COULEUR_COUCHER := Color(0.85, 0.45, 0.15, 0.30)  # orange doux
	const TRANSPARENT := Color(0.0, 0.0, 0.0, 0.0)

	if heure >= 7.0 and heure < 19.0:
		return TRANSPARENT
	elif heure >= 19.0 and heure < SeasonManager.HEURE_COUCHER_SOLEIL:  # 19h-20h : transparent → orange
		var t := (heure - 19.0) / (SeasonManager.HEURE_COUCHER_SOLEIL - 19.0)
		return TRANSPARENT.lerp(COULEUR_COUCHER, t)
	elif heure >= SeasonManager.HEURE_COUCHER_SOLEIL and heure < SeasonManager.HEURE_DEBUT_NUIT:  # 20h-21h : orange → bleu-nuit
		var t := (heure - SeasonManager.HEURE_COUCHER_SOLEIL) / (SeasonManager.HEURE_DEBUT_NUIT - SeasonManager.HEURE_COUCHER_SOLEIL)
		return COULEUR_COUCHER.lerp(COULEUR_NUIT, t)
	elif heure >= SeasonManager.HEURE_DEBUT_NUIT or heure < 5.0:
		return COULEUR_NUIT
	else:  # 5h-7h : lever du soleil
		var t := (heure - 5.0) / 2.0
		return COULEUR_NUIT.lerp(TRANSPARENT, t)
