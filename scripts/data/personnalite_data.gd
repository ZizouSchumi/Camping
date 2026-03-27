class_name PersonnaliteData extends Resource

# PersonnaliteData — Resource définissant les 5 axes de personnalité d'un campeur.
# Créée et assignée par NeedsSystem._initialiser_personnalite() — jamais depuis l'inspecteur.
# Les axes influencent le taux de decay et la priorisation des besoins via modificateur_decay.

@export_range(0.0, 1.0, 0.01) var sociabilite: float = 0.5   # 0=solitaire, 1=très sociable
@export_range(0.0, 1.0, 0.01) var vitalite: float = 0.5      # 0=sédentaire, 1=très actif
@export_range(0.0, 1.0, 0.01) var appetit: float = 0.5       # 0=petit appétit, 1=grand appétit
@export_range(0.0, 1.0, 0.01) var exigence: float = 0.5      # 0=peu exigeant, 1=très exigeant
@export_range(0.0, 1.0, 0.01) var zenitude: float = 0.5      # 0=stressé, 1=très zen


func get_axe(axe_id: String) -> float:
	match axe_id:
		"sociabilite":  return sociabilite
		"vitalite":     return vitalite
		"appetit":      return appetit
		"exigence":     return exigence
		"zenitude":     return zenitude
		_:
			push_warning("PersonnaliteData.get_axe: axe inconnu — " + axe_id)
			return 0.5  # Valeur neutre — ne casse pas le calcul de poids
