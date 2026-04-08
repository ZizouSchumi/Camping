extends CanvasLayer
class_name SpeedHUD

# HUD minimal — affiche la vitesse de simulation actuelle.
# CanvasLayer 1 — non affecté par la caméra ni par Engine.time_scale.

var _label: Label


func _ready() -> void:
	layer = 1
	process_mode = PROCESS_MODE_ALWAYS

	_label = Label.new()
	_label.position = Vector2(16.0, 16.0)
	_label.add_theme_font_size_override("font_size", 20)
	add_child(_label)

	EventBus.subscribe("jeu.vitesse_change", _on_vitesse_change)
	EventBus.subscribe("temps.nouvelle_heure", _on_nouvelle_heure)
	_update_label()


func _exit_tree() -> void:
	EventBus.unsubscribe("jeu.vitesse_change", _on_vitesse_change)
	EventBus.unsubscribe("temps.nouvelle_heure", _on_nouvelle_heure)


func _on_vitesse_change(_payload: Dictionary) -> void:
	_update_label()


func _on_nouvelle_heure(_payload: Dictionary) -> void:
	_update_label()


func _update_label() -> void:
	var h: int = int(SeasonManager.current_hour)
	var m: int = int(fmod(SeasonManager.current_hour, 1.0) * 60.0)
	var time_str: String = "Jour %d — %02d:%02d" % [SeasonManager.current_day, h, m]
	_label.text = "%s   %s" % [time_str, _get_speed_label()]


func _get_speed_label() -> String:
	if SeasonManager.paused:
		return "|| PAUSE"
	match SeasonManager.time_scale:
		1.0: return "> x1"
		2.0: return ">> x2"
		4.0: return ">> x4"
		8.0: return ">> x8"
		12.0: return ">> x12"
	return "> x1"
