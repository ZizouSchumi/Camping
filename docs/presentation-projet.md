# Camping Manager — Présentation du projet

> *Un jeu de gestion de camping où chaque campeur est une personne, pas un sprite.*

**Plateforme :** PC (Steam)
**Genre :** Tycoon / Simulation de gestion 2D
**Dev :** Solo — Zine, avec Godot 4.x

---

## C'est quoi ?

Camping Manager est un tycoon de gestion de camping en vue top-down. Tu construis, configures et fais évoluer ton camping saison après saison.

Ce qui le distingue de tous les autres jeux du genre : **chaque campeur est un individu autonome**, avec sa personnalité propre, ses besoins (manger, dormir, se laver, socialiser), ses préférences et ses relations avec les autres. Tes décisions de gestion créent les conditions dans lesquelles **leurs histoires émergent naturellement** — sans script, sans mise en scène forcée.

**Deux jeux en un :**
- En zoom arrière : un simulateur de gestion profond où tu optimises, planifies, réagis aux crises
- En zoom avant : un générateur d'histoires humaines où tu suis les campeurs individuellement

---

## L'idée centrale

> *"Tout influence tout"*

Le prix de la baguette à la supérette influence la satisfaction des campeurs. Leur satisfaction influence les avis en fin de saison. Les avis influencent ta réputation. Ta réputation influence le profil des campeurs de la saison suivante. Et le profil de tes campeurs influence ce que tu dois construire et proposer.

Rien n'est isolé. Chaque décision crée une chaîne de conséquences **logiques et traçables** — jamais arbitraires, jamais injustes. Si l'inspecteur d'hygiène débarque, c'est parce que les sanitaires n'ont pas été nettoyés depuis 3 jours. Si un campeur tombe malade, tu peux remonter à la cause.

---

## Les piliers de design

1. **Conséquences Logiques** — Le joueur comprend toujours pourquoi quelque chose se passe. Pas de punition random.
2. **Tout Influence Tout** — Profondeur systémique. Chaque décision a des répercussions en cascade.
3. **Campeurs Vivants** — Des PNJ avec une personnalité, des besoins, des affinités et une histoire qui évolue de saison en saison.
4. **Gestion Totale** — Tout est configurable : prix, horaires, menus, planning du personnel, règles internes...
5. **Palette Émotionnelle Complète** — Le jeu fait rire, attendrit, stresse et surprend. Les situations émergentes créent des moments mémorables.
6. **Vibe Été / Nostalgie** — Cigales, piscine, guirlandes le soir, odeur de merguez imaginaire. Lancer le jeu un soir d'hiver et se sentir en vacances.

---

## Comment ça se joue

La boucle est saisonnière :

```
Préparer → Opérer → Bilan → Nouvelle saison
```

**Préparer (inter-saison)**
Construire et placer les infrastructures, configurer les prix et horaires, embaucher le personnel, planifier les animations.

**Opérer (la saison)**
Observer les campeurs, réagir aux crises (orage, intoxication alimentaire, bagarre de voisinage, contrôle d'hygiène surprise), ajuster à la volée. Suivre les histoires qui émergent.

**Bilan (fin de saison)**
Consulter les avis, analyser les finances, voir l'album photo des moments marquants de la saison, décider des investissements pour la suivante.

### Le Directeur — toi

Tu incarnes le directeur. Par défaut il gère tout en automatique. Mais tu peux le prendre en main pour :
- Accueillir et placer les campeurs à leur arrivée (obligatoire si tu n'as pas de réceptionniste)
- Discuter avec un campeur pour enrichir son profil (découvrir ses vraies préférences)
- Désamorcer un conflit de voisinage
- Nettoyer les toilettes toi-même pour économiser sur le staff en début de partie

La pression vers l'embauche est naturelle : à petite échelle, le directeur seul suffit. En croissance, gérer l'accueil + les opérations + les conflits simultanément devient impossible — tu *ressens* le besoin de déléguer.

---

## Les campeurs — le coeur du jeu

Chaque campeur est généré avec :
- Une **personnalité** représentée en axes à curseurs (introverti/extraverti, tolérant/exigeant, festif/calme...)
- Des **besoins hiérarchisés** (manger, dormir, se laver, se divertir, socialiser)
- Des **préférences** sur 5 axes : alimentaire, activités, confort, social, ambiance
- Une **fiche** qui s'enrichit au fil des saisons — un inconnu à sa première visite, un profil détaillé après 3 étés

Les campeurs interagissent entre eux. Un couple calme placé à côté d'une famille festive = conflit probable. Deux familles avec des enfants du même âge = amitié naturelle. Un campeur content contamine positivement ses voisins. Un conflit non résolu crée des "camps" et se propage.

Les **campeurs récurrents** reviennent d'une saison à l'autre avec leur histoire, leurs relations et leurs préférences qui ont évolué. Les deux ados de l'été 1 qui reviennent 10 ans plus tard avec un bébé — c'est le genre de moments que le jeu crée naturellement.

---

## Inspiration & positionnement

| Référence | Ce qu'on prend |
|-----------|----------------|
| **Prison Architect** | Vue top-down lisible, gestion granulaire, événements découlant des décisions |
| **Rimworld** | PNJ avec personnalité générant des histoires, système besoins/humeur, conséquences en chaîne |
| **Two Point Hospital** | Ton humoristique, accessibilité de l'interface, progression par établissement |
| **Les Sims** | Simulation de vie individuelle, attachement aux personnages, relations dynamiques |
| **Planet Zoo** | Satisfaction de construire, profondeur de gestion, système de notation |

### Concurrence directe

Les concurrents sur Steam (Camping Park Simulator, Camping Builder) sont des simulateurs 3D bâclés : placement de bâtiments, aucune profondeur systémique, PNJ sans personnalité. Ils se vendent malgré leur médiocrité — preuve d'un appétit fort pour la niche.

**La niche camping est un désert de qualité.** Camping Manager vise à en être le premier jeu sérieux.

---

## Direction artistique

- **Style :** 2D top-down, sprites simples en vue globale, portraits détaillés au clic
- **Palette :** Chaude et estivale — jaunes, oranges, verts vifs, bleu piscine, guirlandes la nuit
- **Références visuelles :** Prison Architect (lisibilité), Rimworld (portraits), Stardew Valley (palette)
- **Son :** Cigales, splash piscine, rires, musique d'animation le soir. Le soundscape change selon la zone focalisée.
- **Émotes flottantes** au-dessus des campeurs pour lire leur humeur d'un coup d'oeil

---

## Scope V1 (Early Access)

**Inclus :**
- Mode sandbox — lieu unique : Argeles-sur-Mer
- Systèmes core : construction sur grille, configuration, personnel, campeurs autonomes
- Chaînes de conséquences et événements émergents
- Boucle saisonnière complète (préparer → opérer → bilan)
- Système de notation double (standing infrastructure + avis clients subjectifs)
- Interface multi-couches : vue globale, panneaux de gestion, dashboards, zoom campeur

**Post-V1 :**
- Multijoueur (compétitif et coop)
- Lieux supplémentaires (Baléares, Arcachon, Île de Ré)
- Mode scénario avec objectifs de victoire
- Support modding
- Campings voisins / concurrence IA
- Mode Ironman

---

## Contexte de développement

- **Équipe :** Dev solo
- **Moteur :** Godot 4.x (gratuit, excellent 2D, export Steam natif)
- **Approche :** Bootstrap à 0€ — assets gratuits (Kenney.nl, itch.io) pour le prototype, budget art/son à débloquer quand le proto est validé
- **Objectif commercial :** 2 000–5 000 ventes en Early Access à 12-15€, 70%+ d'avis positifs, crédibilité studio pour les projets suivants

---

## Ce qu'on cherche comme feedback

Quelques questions spécifiques si tu veux orienter ton retour :

1. **L'accroche est-elle claire ?** Tu comprends immédiatement ce qui distingue ce jeu des autres tycoons ?
2. **Les campeurs autonomes** — ça semble intéressant comme différenciateur ou trop ambitieux pour croire que ça peut marcher ?
3. **La cible** — tu penses à qui en lisant ça ? C'est cohérent avec ce qui est décrit ?
4. **Quelque chose te fait peur ou te semble irréaliste** dans la vision ?
5. **Qu'est-ce qui t'aurait donné envie d'acheter ça** (ou non) si tu étais le joueur cible ?

---

*Document de présentation — Mars 2026*
*Contact : Zine*
