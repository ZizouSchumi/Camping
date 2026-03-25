extends Node

# SeasonManager — état de la saison, du temps, de la météo
# Référence unique pour le temps de jeu dans tout le projet
# Implémentation complète en S1.5 (E01) et E10

var current_time: float = 0.0   # secondes de jeu
var current_day: int = 1
var current_hour: float = 8.0   # heure du jour (8h = début de journée)
var time_scale: float = 1.0     # multiplicateur de vitesse (1x, 2x, 4x, 8x, 12x)


func _process(delta: float) -> void:
	# Stub — implémenté en S1.5 (E01) et E10
	pass
