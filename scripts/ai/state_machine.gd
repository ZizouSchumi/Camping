class_name StateMachine extends RefCounted

# StateMachine — machine à états pour le comportement autonome du campeur (S2.5)
# États : IDLE (attend décision) → WALKING (se déplace) → ATTENDING (satisfait besoin) → IDLE

const DECISION_INTERVAL: float = 8.0    # secondes de jeu entre deux décisions en état IDLE
const MAX_WALK_TIME: float = 30.0       # timeout de sécurité : retour IDLE si bloqué en WALKING
const SATISFACTION_QUANTITE: float = 0.25  # satisfaction fixe par visite (variable en E03+)

enum Etat { IDLE, WALKING, ATTENDING }

var etat: Etat = Etat.IDLE
var besoin_cible: String = ""
var timer: float = 0.0


func transition_vers(nouvel_etat: Etat) -> void:
	etat = nouvel_etat
	timer = 0.0
