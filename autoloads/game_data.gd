extends Node

# GameData — registry global de toutes les Resources actives du jeu
# Source de vérité pour campeurs, bâtiments, staff en mémoire
# Les panneaux UI lisent via GameData, modifient via EventBus uniquement

var campeurs: Dictionary = {}       # campeur_id → CampeurData
var batiments: Dictionary = {}      # batiment_id → BatimentData
var staff_members: Dictionary = {}  # staff_id → StaffData
