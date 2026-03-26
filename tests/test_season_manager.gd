extends GutTest

# Tests unitaires pour SeasonManager
# Vérifie la gestion de la vitesse, de la pause et de current_time.

var _sm: Node


func before_each() -> void:
	_sm = load("res://autoloads/season_manager.gd").new()
	add_child(_sm)


func after_each() -> void:
	_sm.queue_free()


func test_vitesse_defaut() -> void:
	assert_eq(_sm.time_scale, 1.0, "Vitesse par défaut doit être x1")
	assert_false(_sm.paused, "Pas en pause par défaut")


func test_toggle_pause() -> void:
	_sm.toggle_pause()
	assert_true(_sm.paused, "toggle_pause() doit mettre en pause")
	_sm.toggle_pause()
	assert_false(_sm.paused, "Deuxième toggle doit désactiver la pause")


func test_set_speed() -> void:
	_sm.set_speed(4.0)
	assert_eq(_sm.time_scale, 4.0, "set_speed(4.0) doit définir time_scale à 4.0")
	assert_false(_sm.paused, "set_speed() doit désactiver la pause")


func test_set_speed_invalide() -> void:
	_sm.set_speed(7.0)
	assert_eq(_sm.time_scale, 1.0, "Vitesse invalide ne doit pas changer time_scale")


func test_speed_up_cycle() -> void:
	_sm.set_speed(1.0)
	_sm.speed_up()
	assert_eq(_sm.time_scale, 2.0, "speed_up() depuis x1 doit donner x2")


func test_speed_down_clamp() -> void:
	_sm.set_speed(1.0)
	_sm.speed_down()
	assert_eq(_sm.time_scale, 1.0, "speed_down() depuis x1 doit rester à x1")


func test_speed_up_clamp_max() -> void:
	_sm.set_speed(12.0)
	_sm.speed_up()
	assert_eq(_sm.time_scale, 12.0, "speed_up() depuis x12 doit rester à x12")


func test_current_time_gele_en_pause() -> void:
	_sm.paused = true
	var time_avant: float = _sm.current_time
	_sm._process(0.1)
	assert_eq(_sm.current_time, time_avant, "current_time ne doit pas avancer en pause")


func test_current_time_avance_hors_pause() -> void:
	_sm.paused = false
	_sm.time_scale = 1.0
	_sm.current_time = 0.0
	_sm._process(0.1)
	assert_almost_eq(_sm.current_time, 0.1, 0.001, "current_time doit avancer de delta * time_scale")

func test_heure_initiale() -> void:
	assert_almost_eq(_sm.current_hour, 8.0, 0.001, "current_hour doit démarrer à 8h00")

func test_avancement_heure() -> void:
	_sm.current_time = 0.0
	_sm.paused = false
	_sm.time_scale = 1.0
	# Avancer d'exactement une heure de jeu
	_sm._process(_sm.SECONDS_PER_GAME_HOUR)
	assert_almost_eq(_sm.current_hour, 9.0, 0.01, "Après 1h de jeu, current_hour doit être 9h")

func test_transition_jour() -> void:
	_sm.current_time = 0.0
	_sm.paused = false
	_sm.time_scale = 1.0
	# Avancer d'une journée complète (24h)
	_sm._process(_sm.SECONDS_PER_DAY)
	assert_eq(_sm.current_day, 2, "Après 24h de jeu, current_day doit être 2")

func test_vitesse_x2_double_avancement() -> void:
	_sm.current_time = 0.0
	_sm.paused = false

	_sm.time_scale = 1.0
	_sm._process(1.0)
	var time_x1: float = _sm.current_time

	_sm.current_time = 0.0
	_sm.time_scale = 2.0
	_sm._process(1.0)
	var time_x2: float = _sm.current_time

	assert_almost_eq(time_x2, time_x1 * 2.0, 0.001, "x2 doit avancer 2× plus vite que x1")
