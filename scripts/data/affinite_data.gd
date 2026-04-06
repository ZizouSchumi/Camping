class_name AffiniteData extends Resource

# AffiniteData — score d'affinité entre deux campeurs (Story 4.2)
# Clé dans GameData.affinites : "c_001|c_002" (IDs triés alphabétiquement)

@export var campeur_a_id: String = ""
@export var campeur_b_id: String = ""
@export var score: float = 0.5           # 0.0 = antipathie max, 1.0 = affinité max
@export var nb_rencontres: int = 0
@export var derniere_rencontre: float = 0.0  # elapsed_game_time de la dernière rencontre
