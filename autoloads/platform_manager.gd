extends Node

# PlatformManager — abstraction de la plateforme Steam
# Stub fonctionnel jusqu'à E15 (intégration GodotSteam réelle)
# OBLIGATOIRE : ne jamais appeler GodotSteam directement — toujours PlatformManager


func unlock_achievement(id: String) -> void:
	print("PlatformManager [stub] unlock_achievement: ", id)


func save_to_cloud(filename: String, data: String) -> void:
	print("PlatformManager [stub] save_to_cloud: ", filename)
	# En production (E15) : GodotSteam.ugcStoreWorkshopFiles()


func get_player_name() -> String:
	return "Player"  # Stub — retourne le vrai nom Steam en E15
