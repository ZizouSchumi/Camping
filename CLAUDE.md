# Camping Manager — Instructions projet

## Contexte
Godot 4 / GDScript — simulation de camping (agents autonomes, économie, saisons).
Tests avec GUT. Workflow BMAD pack GDS. Langue : français.

## Patterns critiques GDScript
- `extends "res://path.gd"` + `class_name` séparé (jamais `extends ClassName`)
- Tests GUT : `assert_push_error_count(n, "msg")` pour les `push_error` attendus — appel **après** le code testé, jamais avec `:` (pas de bloc GDScript)

## Compact
Lors de la compaction, préserver en priorité :
1. Story active (épic/story, fichiers modifiés, état)
2. Patterns GDScript et conventions GUT ci-dessus
3. Décisions d'architecture en cours
