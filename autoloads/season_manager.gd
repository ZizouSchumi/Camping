extends Node

# SeasonManager — source de vérité pour le temps de jeu.
# Gère : vitesse de simulation, heures, jours, ticks périodiques.
# Ne pas utiliser Engine.time_scale — tout passe par time_scale ici.

const SPEEDS: Array[float] = [1.0, 2.0, 4.0, 8.0, 12.0]
const SECONDS_PER_GAME_HOUR: float = 60.0
const HOURS_PER_DAY: int = 24
const START_HOUR: float = 8.0
const SECONDS_PER_DAY: float = SECONDS_PER_GAME_HOUR * HOURS_PER_DAY
const HEURE_COUCHER_SOLEIL: float = 20.0  # Pic du coucher (orange) — centre de la transition 19h-21h
const HEURE_LEVER_SOLEIL: float = 7.0    # Fin du lever — fin de la transition 5h-7h
const HEURE_DEBUT_NUIT: float = 21.0     # Nuit pleine (overlay + comportements nocturnes NeedsSystem)

var current_time: float = 0.0
var current_day: int = 1
var current_hour: float = START_HOUR
var time_scale: float = 1.0
var paused: bool = false

var _speed_index: int = 0
var _last_hour: int = int(START_HOUR)
var _last_day: int = 1


func is_nuit() -> bool:
	return current_hour >= HEURE_DEBUT_NUIT or current_hour < HEURE_LEVER_SOLEIL


func _process(delta: float) -> void:
	if paused:
		return
	current_time += delta * time_scale
	_update_time()


func _update_time() -> void:
	var total_hours: float = current_time / SECONDS_PER_GAME_HOUR
	current_hour = fmod(total_hours + START_HOUR, float(HOURS_PER_DAY))
	current_day = int(total_hours / float(HOURS_PER_DAY)) + 1

	var hour_int: int = int(current_hour)
	if hour_int != _last_hour:
		_last_hour = hour_int
		EventBus.emit("temps.nouvelle_heure", {
			"entite_id": "world",
			"timestamp": current_time,
			"heure": hour_int,
			"jour": current_day,
		})

	if current_day != _last_day:
		_last_day = current_day
		EventBus.emit("temps.nouveau_jour", {
			"entite_id": "world",
			"timestamp": current_time,
			"jour": current_day,
		})


func toggle_pause() -> void:
	paused = not paused
	_emit_speed_event()


func set_speed(speed: float) -> void:
	var idx: int = SPEEDS.find(speed)
	if idx == -1:
		return
	_speed_index = idx
	time_scale = SPEEDS[_speed_index]
	paused = false
	_emit_speed_event()


func speed_up() -> void:
	_speed_index = mini(_speed_index + 1, SPEEDS.size() - 1)
	time_scale = SPEEDS[_speed_index]
	paused = false
	_emit_speed_event()


func speed_down() -> void:
	_speed_index = maxi(_speed_index - 1, 0)
	time_scale = SPEEDS[_speed_index]
	paused = false
	_emit_speed_event()


func _emit_speed_event() -> void:
	EventBus.emit("jeu.vitesse_change", {
		"entite_id": "world",
		"timestamp": current_time,
		"vitesse": time_scale,
		"en_pause": paused,
	})
