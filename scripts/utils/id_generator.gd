class_name IDGenerator extends RefCounted

# IDGenerator — générateur d'identifiants uniques par type d'entité.
# Les compteurs sont statiques (uniques par session de jeu).
# Le SaveSystem devra persister ces valeurs pour garantir l'unicité inter-sessions.

static var _campeur_counter: int = 0

static func generate_campeur_id() -> String:
	_campeur_counter += 1
	return "c_%03d" % _campeur_counter

# Stub pour E03 — Bâtiments
static var _batiment_counter: int = 0
static func generate_batiment_id() -> String:
	_batiment_counter += 1
	return "b_%03d" % _batiment_counter

# Stub pour E06 — Staff
# static var _staff_counter: int = 0
# static func generate_staff_id() -> String:
#     _staff_counter += 1
#     return "s_%03d" % _staff_counter
