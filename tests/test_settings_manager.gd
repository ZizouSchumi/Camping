extends GutTest

# Tests unitaires pour PlatformManager — gestion des paramètres (settings)
# Vérifie : defaults, save/load, roundtrip, toggle, clamping, buses manquants.

const TEST_SETTINGS_PATH := "user://test_settings.cfg"

var _platform: Node


func before_each() -> void:
	_platform = load("res://autoloads/platform_manager.gd").new()
	_platform.SETTINGS_PATH = TEST_SETTINGS_PATH
	add_child(_platform)


func after_each() -> void:
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(TEST_SETTINGS_PATH)
	_platform.queue_free()


func test_load_settings_defaults_when_no_file() -> void:
	var s: SettingsData = _platform.load_settings()
	assert_eq(s.resolution_index, 1, "résolution par défaut doit être index 1 (1080p)")
	assert_false(s.fullscreen, "plein écran désactivé par défaut")
	assert_almost_eq(s.volume_master, 1.0, 0.001, "volume master par défaut : 1.0")
	assert_almost_eq(s.volume_music, 0.8, 0.001, "volume musique par défaut : 0.8")
	assert_almost_eq(s.volume_sfx, 1.0, 0.001, "volume SFX par défaut : 1.0")


func test_save_load_roundtrip() -> void:
	_platform.settings = SettingsData.new()
	_platform.settings.resolution_index = 2
	_platform.settings.fullscreen = true
	_platform.settings.volume_master = 0.5
	_platform.settings.volume_music = 0.3
	_platform.settings.volume_sfx = 0.7
	_platform.save_settings()

	var loaded: SettingsData = _platform.load_settings()
	assert_eq(loaded.resolution_index, 2, "resolution_index doit survivre le roundtrip")
	assert_true(loaded.fullscreen, "fullscreen doit survivre le roundtrip")
	assert_almost_eq(loaded.volume_master, 0.5, 0.001, "volume_master doit survivre le roundtrip")
	assert_almost_eq(loaded.volume_music, 0.3, 0.001, "volume_music doit survivre le roundtrip")
	assert_almost_eq(loaded.volume_sfx, 0.7, 0.001, "volume_sfx doit survivre le roundtrip")


func test_toggle_fullscreen_bascule() -> void:
	_platform.settings = SettingsData.new()
	_platform.settings.fullscreen = false
	_platform.toggle_fullscreen()
	assert_true(_platform.settings.fullscreen, "toggle_fullscreen doit activer plein écran")
	_platform.toggle_fullscreen()
	assert_false(_platform.settings.fullscreen, "toggle_fullscreen x2 doit revenir en fenêtré")


func test_set_fullscreen_direct() -> void:
	_platform.settings = SettingsData.new()
	_platform.set_fullscreen(true)
	assert_true(_platform.settings.fullscreen, "set_fullscreen(true) doit activer plein écran")
	_platform.set_fullscreen(false)
	assert_false(_platform.settings.fullscreen, "set_fullscreen(false) doit désactiver plein écran")


func test_set_resolution_valide() -> void:
	_platform.settings = SettingsData.new()
	_platform.set_resolution(0)
	assert_eq(_platform.settings.resolution_index, 0, "set_resolution(0) doit passer à 1280×720")
	_platform.set_resolution(3)
	assert_eq(_platform.settings.resolution_index, 3, "set_resolution(3) doit passer à 4K")


func test_set_resolution_invalide_ne_crash_pas() -> void:
	_platform.settings = SettingsData.new()
	var idx_avant: int = _platform.settings.resolution_index
	_platform.set_resolution(-1)
	assert_eq(_platform.settings.resolution_index, idx_avant, "set_resolution(-1) ne doit pas modifier l'index")
	_platform.set_resolution(999)
	assert_eq(_platform.settings.resolution_index, idx_avant, "set_resolution(999) ne doit pas modifier l'index")


func test_set_volume_master_clampe_au_dessus() -> void:
	_platform.settings = SettingsData.new()
	_platform.set_volume_master(1.5)
	assert_almost_eq(_platform.settings.volume_master, 1.0, 0.001, "volume master clampé à 1.0")


func test_set_volume_master_clampe_en_dessous() -> void:
	_platform.settings = SettingsData.new()
	_platform.set_volume_master(-0.5)
	assert_almost_eq(_platform.settings.volume_master, 0.0, 0.001, "volume master clampé à 0.0")


func test_set_volume_music_clampe() -> void:
	_platform.settings = SettingsData.new()
	_platform.set_volume_music(2.0)
	assert_almost_eq(_platform.settings.volume_music, 1.0, 0.001, "volume music clampé à 1.0")


func test_set_volume_sfx_clampe() -> void:
	_platform.settings = SettingsData.new()
	_platform.set_volume_sfx(-1.0)
	assert_almost_eq(_platform.settings.volume_sfx, 0.0, 0.001, "volume SFX clampé à 0.0")


func test_apply_audio_settings_ne_crash_pas_si_bus_manquants() -> void:
	# Music et SFX peuvent ne pas exister dans le projet par défaut — pas de crash attendu
	_platform.settings = SettingsData.new()
	_platform.apply_audio_settings()
	assert_true(true, "apply_audio_settings() ne crashe pas si buses Music/SFX absents")


func test_load_settings_fichier_corrompu_retourne_defaults() -> void:
	# Écrire un fichier cfg invalide
	var f := FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	f.store_string("ceci n'est pas un cfg valide ###")
	f.close()
	var s: SettingsData = _platform.load_settings()
	# ConfigFile.load() échouera → defaults retournés (M5 fix : assertions renforcées)
	assert_not_null(s, "load_settings() doit retourner un SettingsData même sur fichier corrompu")
	assert_eq(s.resolution_index, 1, "résolution par défaut doit être restaurée sur fichier corrompu")
	assert_false(s.fullscreen, "fullscreen par défaut doit être restauré sur fichier corrompu")
	assert_almost_eq(s.volume_master, 1.0, 0.001, "volume master par défaut doit être restauré sur fichier corrompu")
	assert_almost_eq(s.volume_music, 0.8, 0.001, "volume music par défaut doit être restauré sur fichier corrompu")
	assert_almost_eq(s.volume_sfx, 1.0, 0.001, "volume SFX par défaut doit être restauré sur fichier corrompu")


func test_settings_data_quatre_resolutions_disponibles() -> void:
	# M6 fix : AC1 — exactement 4 résolutions connues doivent être disponibles
	assert_eq(SettingsData.RESOLUTIONS.size(), 4, "AC1 : exactement 4 résolutions doivent être définies")
	assert_eq(SettingsData.RESOLUTIONS[0], Vector2i(1280, 720), "résolution 0 doit être 720p")
	assert_eq(SettingsData.RESOLUTIONS[1], Vector2i(1920, 1080), "résolution 1 doit être 1080p")
	assert_eq(SettingsData.RESOLUTIONS[2], Vector2i(2560, 1440), "résolution 2 doit être 1440p")
	assert_eq(SettingsData.RESOLUTIONS[3], Vector2i(3840, 2160), "résolution 3 doit être 4K")


# --- Tests Steam (Story 1.8) ---

func test_is_steam_available_false_sans_godotsteam() -> void:
	# Sans GodotSteam installé, Steam ne peut pas être disponible — AC4
	assert_false(_platform.is_steam_available(), "is_steam_available() doit retourner false sans GodotSteam")


func test_get_player_name_retourne_player_sans_steam() -> void:
	# Sans Steam, get_player_name() doit retourner "Player" — AC5 + AC6 (zéro régression)
	# Note: variable locale renommée "persona" pour éviter le shadowing de Node.name
	assert_eq(_platform.get_player_name(), "Player", "get_player_name() doit retourner 'Player' sans Steam")
