extends Node
class_name TimeController

# Gestion des inputs clavier pour les contrôles de vitesse.
# Délègue toute la logique à SeasonManager — pas d'état ici.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		SeasonManager.toggle_pause()
	elif event.is_action_pressed("game_speed_up"):
		SeasonManager.speed_up()
	elif event.is_action_pressed("game_speed_down"):
		SeasonManager.speed_down()
