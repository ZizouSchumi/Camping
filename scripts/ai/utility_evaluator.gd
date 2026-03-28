class_name UtilityEvaluator extends RefCounted

# UtilityEvaluator — évalue l'urgence d'un besoin pour l'IA de décision (S2.5)
# Score = 0.0 si besoin satisfait (valeur = 1.0), croît avec l'urgence


static func score_besoin(besoin: BesoinData) -> float:
	return (1.0 - besoin.valeur_actuelle) * besoin.modificateur_decay
