# GodotSteam — Setup (approche module précompilé)

## Pourquoi cette approche ?

GodotSteam pour Godot 4.6 n'est **pas** un plugin GDExtension.
C'est un **éditeur Godot custom** avec Steam compilé dedans, distribué avec des templates d'export dédiés.

## Version à utiliser

**GodotSteam v4.17.1** — Godot 4.6 / Steamworks 1.63
- Page releases principale : https://codeberg.org/GodotSteam/GodotSteam/releases
  (le GitHub est un miroir de débordement — les fichiers Windows sont sur Codeberg)

## Étapes d'installation

### 1 — Télécharger l'éditeur GodotSteam (Windows)

Sur Codeberg → v4.17.1 → asset `windows-g46-s163-gs4171-editor.zip` (ou similaire)

Extraire dans un dossier dédié, ex: `C:\GodotSteam\`.
Ce binaire **remplace** l'éditeur Godot standard pour ce projet.

### 2 — Télécharger les templates d'export GodotSteam

Asset : `godotsteam-g46-s163-gs4171-templates.tar.xz`

Dans l'éditeur GodotSteam :
- Editor → Manage Export Templates → Install from file → sélectionner le .tar.xz

### 3 — Installer le SDK Steamworks

- Créer un compte développeur Steam sur https://partner.steamgames.com/
- Télécharger le SDK Steamworks
- Copier `redistributable_bin/win64/steam_api64.dll` à la **racine de ce projet**
  (à côté de `project.godot`)

> `steam_api64.dll` est dans `.gitignore` — ne jamais committer.

### 4 — Ouvrir le projet dans l'éditeur GodotSteam

Ouvrir `project.godot` avec l'éditeur GodotSteam (pas le Godot standard).
Le singleton `Steam` est disponible automatiquement — aucune activation de plugin requise.

### 5 — Vérifier steam_appid.txt

Le fichier `steam_appid.txt` à la racine contient `480` (SpaceWar — app ID de test Valve).
Remplacer par l'app ID réel une fois le jeu enregistré sur Steamworks.

### 6 — Smoke test

1. Lancer le jeu en Play Mode dans l'éditeur GodotSteam
2. Avec Steam ouvert : `PlatformManager: Steam initialisé — joueur : [ton nom Steam]` dans Output
3. Sans Steam ouvert : `PlatformManager: Steam non disponible — ...` (warning, pas d'erreur)

### 7 — Export Windows Desktop

- Project → Export → Windows Desktop
- Utiliser les templates GodotSteam (installés à l'étape 2)
- Inclure `steam_api64.dll` dans les fichiers à copier à côté du binaire exporté

## Développement quotidien

Toujours utiliser l'éditeur **GodotSteam** (pas Godot standard) pour ce projet.
Le singleton `Steam` n'est disponible que dans l'éditeur GodotSteam.

`PlatformManager.is_steam_available()` retourne :
- `true` si Steam est initialisé (éditeur GodotSteam + client Steam ouvert)
- `false` dans tous les autres cas (éditeur standard, Steam fermé, etc.) — le jeu continue sans crash
