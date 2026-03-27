class_name BesoinData extends Resource

# BesoinData — Resource représentant un besoin individuel d'un campeur.
# Créé et géré exclusivement par NeedsSystem — ne pas modifier directement.

@export var besoin_id: String = ""
@export var niveau: String = "primaire"  # "primaire" | "secondaire" | "tertiaire"
@export var valeur_actuelle: float = 1.0  # 0.0 = critique, 1.0 = pleinement satisfait
@export var taux_decay: float = 0.001    # Décroissance par seconde de temps de jeu
@export var seuil_critique: float = 0.2
@export var seuil_eleve: float = 0.4
@export var seuil_satisfait: float = 0.7
var modificateur_decay: float = 1.0
# Mis à jour par NeedsSystem._appliquer_poids_personnalite() — valeur par défaut 1.0 = comportement S2.2


func get_etat() -> String:
	if valeur_actuelle >= seuil_satisfait:
		return "satisfait"
	elif valeur_actuelle >= seuil_eleve:
		return "moyen"
	elif valeur_actuelle >= seuil_critique:
		return "eleve"
	else:
		return "critique"
