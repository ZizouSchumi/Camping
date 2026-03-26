extends CanvasLayer
class_name SettingsPanel

# Panneau paramètres — résolution, plein écran, volumes.
# Construit programmatiquement (pas de .tscn), pattern cohérent avec les autres composants.
# F10 : ouvrir/fermer  |  F11 : toggle plein écran  |  Échap : fermer si ouvert.

const RESOLUTION_LABELS: Array[String] = ["1280x720", "1920x1080", "2560x1440", "3840x2160"]

var _resolution_option: OptionButton
var _fullscreen_check: CheckButton
var _slider_master: HSlider
var _slider_music: HSlider
var _slider_sfx: HSlider
var _populating: bool = false


func _ready() -> void:
	layer = 10
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()
	_populate_from_settings()
	visibility_changed.connect(_on_visibility_changed)


func _build_ui() -> void:
	# Conteneur plein écran
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Fond semi-transparent
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	# Centrage
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	# Panneau principal
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 0.0)
	center.add_child(panel)

	# M4 fix : marges internes pour éviter le contenu flush aux bords
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Titre
	var title := Label.new()
	title.text = "Parametres"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Résolution
	_resolution_option = _add_option_row(vbox, "Resolution :", RESOLUTION_LABELS)
	_resolution_option.item_selected.connect(_on_resolution_selected)

	# Plein écran
	_fullscreen_check = _add_check_row(vbox, "Plein ecran :")
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	vbox.add_child(HSeparator.new())

	# Volumes — H1 fix : value_changed = preview (save=false), drag_ended = persist
	_slider_master = _add_volume_row(vbox, "Volume general :")
	_slider_master.value_changed.connect(func(v: float) -> void:
		if not _populating:
			PlatformManager.set_volume_master(v, false)
	)
	_slider_master.drag_ended.connect(func(_changed: bool) -> void:
		PlatformManager.save_settings()
	)

	_slider_music = _add_volume_row(vbox, "Volume musique :")
	_slider_music.value_changed.connect(func(v: float) -> void:
		if not _populating:
			PlatformManager.set_volume_music(v, false)
	)
	_slider_music.drag_ended.connect(func(_changed: bool) -> void:
		PlatformManager.save_settings()
	)

	_slider_sfx = _add_volume_row(vbox, "Volume SFX :")
	_slider_sfx.value_changed.connect(func(v: float) -> void:
		if not _populating:
			PlatformManager.set_volume_sfx(v, false)
	)
	_slider_sfx.drag_ended.connect(func(_changed: bool) -> void:
		PlatformManager.save_settings()
	)

	vbox.add_child(HSeparator.new())

	# Bouton fermer
	var btn := Button.new()
	btn.text = "Fermer  [F10]"
	btn.pressed.connect(func() -> void: visible = false)
	vbox.add_child(btn)


func _add_option_row(parent: VBoxContainer, label_text: String, items: Array[String]) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 170.0
	row.add_child(lbl)
	var opt := OptionButton.new()
	opt.custom_minimum_size.x = 200.0
	for item: String in items:
		opt.add_item(item)
	row.add_child(opt)
	return opt


func _add_check_row(parent: VBoxContainer, label_text: String) -> CheckButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 170.0
	row.add_child(lbl)
	var check := CheckButton.new()
	row.add_child(check)
	return check


func _add_volume_row(parent: VBoxContainer, label_text: String) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 170.0
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size.x = 230.0
	row.add_child(slider)
	return slider


func _populate_from_settings() -> void:
	_populating = true
	var s := PlatformManager.settings
	_resolution_option.select(s.resolution_index)
	_fullscreen_check.button_pressed = s.fullscreen
	_slider_master.value = s.volume_master
	_slider_music.value = s.volume_music
	_slider_sfx.value = s.volume_sfx
	_populating = false


func _on_resolution_selected(index: int) -> void:
	if not _populating:
		PlatformManager.set_resolution(index)


func _on_fullscreen_toggled(pressed: bool) -> void:
	if not _populating:
		PlatformManager.set_fullscreen(pressed)


func _on_visibility_changed() -> void:
	if visible:
		_populate_from_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		PlatformManager.toggle_fullscreen()
		if visible:
			_populate_from_settings()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_settings"):
		visible = not visible
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
