# Camping Manager

> *Un jeu de gestion de camping où chaque campeur est une personne, pas un sprite.*

**Plateforme :** PC (Steam) | **Genre :** Tycoon / Simulation 2D | **Engine :** Godot 4.x | **Dev :** Solo

---

## C'est quoi ?

Camping Manager est un tycoon de gestion en vue top-down. Tu construis et fais évoluer ton camping saison après saison.

Ce qui le distingue : **chaque campeur est un individu autonome** avec sa personnalité, ses besoins (manger, dormir, se laver, socialiser), ses préférences et ses relations. Tes décisions créent les conditions dans lesquelles **leurs histoires émergent naturellement** — sans script, sans mise en scène forcée.

**Deux expériences en une :**
- En zoom arrière : un simulateur de gestion profond où tu optimises, planifies, réagis aux crises
- En zoom avant : un générateur d'histoires humaines où tu suis les campeurs individuellement

---

## L'idée centrale

> *"Tout influence tout"*

Le prix de la baguette influence la satisfaction des campeurs → les avis de fin de saison → ta réputation → le profil des campeurs suivants → ce que tu dois construire.

Rien n'est isolé. Si l'inspecteur d'hygiène débarque, c'est parce que les sanitaires n'ont pas été nettoyés depuis 3 jours. Si un campeur tombe malade, tu peux remonter à la cause.

---

## Boucle de jeu

```
Préparer → Opérer → Bilan → Nouvelle saison
```

- **Préparer** — Construire, configurer les prix, embaucher, planifier
- **Opérer** — Observer, réagir aux crises, suivre les histoires émergentes
- **Bilan** — Avis, finances, album photo de la saison, investissements futurs

---

## Stack technique

- **Godot 4.x** (GDScript)
- **GUT** — framework de tests unitaires
- **GodotSteam** — intégration Steam

## Structure du projet

```
autoloads/       # Singletons (GameData, GridSystem, NeedsSystem, SeasonManager, SaveSystem...)
scenes/          # Scènes Godot (world, UI, bâtiments, campeurs...)
scripts/         # Scripts utilitaires et données
assets/          # Audio, sprites, tilesets
tests/           # Tests unitaires GUT
```

---

*Développé par Zine — 2026*
