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
@export var note_finale: int = 0          # 0 = pas encore noté, 1-5 étoiles (S4.5)
@export var commentaire_final: String = ""  # Généré à la sortie (S4.5)

var besoins: Dictionary = {}  # besoin_id → BesoinData — initialisé et mis à jour exclusivement par NeedsSystem
var personnalite: PersonnaliteData = null  # Assignée par NeedsSystem._initialiser_personnalite() — null avant register_campeur
var world_position: Vector2 = Vector2.ZERO  # Runtime — mis à jour par campeur.gd._physics_process(), non persisté
var satisfaction_moyenne: float = 0.0     # EWMA de la satisfaction sur le séjour (S4.5) — runtime, non persisté


func is_valid() -> bool:
	return campeur_id != "" and prenom != ""
