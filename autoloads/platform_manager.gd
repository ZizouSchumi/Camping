extends Node

# PlatformManager — abstraction de la plateforme Steam + paramètres utilisateur.
# Stub fonctionnel si GodotSteam non installé ou Steam non disponible.
# OBLIGATOIRE : ne jamais appeler GodotSteam directement — toujours PlatformManager.
# OBLIGATOIRE : seul autoload autorisé à toucher DisplayServer et AudioServer.

var SETTINGS_PATH: String = "user://settings.cfg"  # var pour override dans les tests

var settings: SettingsData
var _steam_available: bool = false
# Référence Variant au singleton Steam — évite les parse errors quand GodotSteam absent.
# Ne jamais typer cette variable : le parser GDScript validerait Steam au chargement.
var _steam = null


func _ready() -> void:
	_init_steam()
	settings = load_settings()
	apply_display_settings()
	apply_audio_settings()


func _process(_delta: float) -> void:
	# run_callbacks() OBLIGATOIRE chaque frame pour que les signaux Steam se déclenchent.
	# Sans cet appel, aucun événement Steam (achievements, cloud, overlay...) ne fonctionne.
	if _steam_available:
		_steam.run_callbacks()


# --- Steam ---

func _init_steam() -> void:
	if not Engine.has_singleton("Steam"):
		print("PlatformManager: GodotSteam absent — mode stub actif (éditeur standard)")
		set_process(false)
		return

	_steam = Engine.get_singleton("Steam")
	var init_response: Dictionary = _steam.steamInitEx()
	# STEAM_API_INIT_RESULT_OK = 0 (valeur documentée Steamworks SDK)
	if init_response.get("status", -1) == 0:
		_steam_available = true
		set_process(true)
		print("PlatformManager: Steam initialisé — joueur : ", _steam.getPersonaName())
	else:
		print("PlatformManager: Steam non disponible — ", init_response.get("verbal", "erreur inconnue"))
		_steam = null
		set_process(false)


func is_steam_available() -> bool:
	return _steam_available


func unlock_achievement(id: String) -> void:
	if _steam_available:
		_steam.setAchievement(id)
		_steam.storeStats()
	else:
		print("PlatformManager [stub] unlock_achievement: ", id)


func save_to_cloud(filename: String, _data: String) -> void:
	if _steam_available:
		push_warning("PlatformManager: save_to_cloud('%s') non implémenté — TODO E15" % filename)
	else:
		print("PlatformManager [stub] save_to_cloud: ", filename)


func get_player_name() -> String:
	if _steam_available:
		var persona: String = _steam.getPersonaName()
		return persona if not persona.is_empty() else "Player"
	return "Player"


# --- Settings : persistance ---

func load_settings() -> SettingsData:
	var data := SettingsData.new()
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return data
	data.resolution_index = cfg.get_value("display", "resolution_index", data.resolution_index)
	data.fullscreen = cfg.get_value("display", "fullscreen", data.fullscreen)
	data.volume_master = cfg.get_value("audio", "volume_master", data.volume_master)
	data.volume_music = cfg.get_value("audio", "volume_music", data.volume_music)
	data.volume_sfx = cfg.get_value("audio", "volume_sfx", data.volume_sfx)
	return data


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "resolution_index", settings.resolution_index)
	cfg.set_value("display", "fullscreen", settings.fullscreen)
	cfg.set_value("audio", "volume_master", settings.volume_master)
	cfg.set_value("audio", "volume_music", settings.volume_music)
	cfg.set_value("audio", "volume_sfx", settings.volume_sfx)
	cfg.save(SETTINGS_PATH)


# --- Settings : affichage ---

func apply_display_settings() -> void:
	if settings == null:
		push_error("PlatformManager: apply_display_settings() appelé avant _ready()")
		return
	var res: Vector2i = SettingsData.RESOLUTIONS[settings.resolution_index]
	DisplayServer.window_set_size(res)
	var mode: DisplayServer.WindowMode = (
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if settings.fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_mode(mode)


func toggle_fullscreen() -> void:
	settings.fullscreen = not settings.fullscreen
	apply_display_settings()
	save_settings()


func set_fullscreen(value: bool) -> void:
	settings.fullscreen = value
	apply_display_settings()
	save_settings()


func set_resolution(index: int) -> void:
	if index < 0 or index >= SettingsData.RESOLUTIONS.size():
		push_warning("PlatformManager: index de résolution invalide : %d" % index)
		return
	settings.resolution_index = index
	apply_display_settings()
	save_settings()


# --- Settings : audio ---

func apply_audio_settings() -> void:
	if settings == null:
		push_error("PlatformManager: apply_audio_settings() appelé avant _ready()")
		return
	_set_bus_volume("Master", settings.volume_master)
	_set_bus_volume("Music", settings.volume_music)
	_set_bus_volume("SFX", settings.volume_sfx)


# save=true (défaut) : applique + persiste. save=false : applique seulement (pour preview slider).
func set_volume_master(linear: float, save: bool = true) -> void:
	settings.volume_master = clampf(linear, 0.0, 1.0)
	_set_bus_volume("Master", settings.volume_master)
	if save:
		save_settings()


func set_volume_music(linear: float, save: bool = true) -> void:
	settings.volume_music = clampf(linear, 0.0, 1.0)
	_set_bus_volume("Music", settings.volume_music)
	if save:
		save_settings()


func set_volume_sfx(linear: float, save: bool = true) -> void:
	settings.volume_sfx = clampf(linear, 0.0, 1.0)
	_set_bus_volume("SFX", settings.volume_sfx)
	if save:
		save_settings()


func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	# maxf(0.0001) évite linear_to_db(0.0) = -INF (comportement non documenté)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(0.0001, linear_volume)))
