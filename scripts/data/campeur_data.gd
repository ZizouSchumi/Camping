class_name CampeurData extends Resource

# CampeurData — Resource de données d'un campeur.
# Passé à Campeur.initialize() après instanciation de la scène.
# Ne pas modifier directement depuis l'extérieur — toujours via campeur.gd.

@export var campeur_id: String = ""
@export var prenom: String = ""
@export var age: int = 0
@export var genre: String = "autre"  # "homme" | "femme" | "autre"
@export var date_arrivee: float = 0.0
@export var date_depart_prevue: float = 0.0
@export var emplacement_id: String = ""


func is_valid() -> bool:
	return campeur_id != "" and prenom != ""


# Stubs pour stories futures (commentés pour éviter les dépendances circulaires) :
# var besoins: Array[BesoinInstance] = []     # S2.2 — Système de besoins
# var personnalite: PersonnaliteData = null   # S2.3 — Système de personnalité
