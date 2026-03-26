class_name SettingsData
extends Resource

# Données de configuration du joueur — résolution, plein écran, volumes.
# Persisté via ConfigFile dans user://settings.cfg (PlatformManager).

const RESOLUTIONS: Array = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

@export var resolution_index: int = 1   # 1920×1080 par défaut
@export var fullscreen: bool = false
@export var volume_master: float = 1.0  # 0.0 – 1.0
@export var volume_music: float = 0.8
@export var volume_sfx: float = 1.0
