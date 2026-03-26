class_name Campeur extends CharacterBody2D

# campeur.gd — Entité PNJ campeur.
# Utiliser initialize(data) après add_child() — NE PAS appeler dans _ready().
# Le pathfinding (NavigationAgent2D) sera activé en S2.4.

var campeur_id: String = ""
var _data: CampeurData = null


func _ready() -> void:
	# Texture placeholder bleue — évite les warnings "texture null" de Godot 4.x
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.29, 0.565, 0.851))  # #4A90D9
	$Sprite2D.texture = ImageTexture.create_from_image(img)


func initialize(data: CampeurData, spawn_position: Vector2 = Vector2.ZERO) -> void:
	if not data.is_valid():
		push_error("Campeur.initialize: CampeurData invalide — campeur_id ou prenom vide")
		return

	campeur_id = data.campeur_id
	_data = data
	position = spawn_position

	# Mise à jour visuelle
	$Label.text = data.prenom

	# Enregistrement dans les systèmes globaux
	GameData.campeurs[campeur_id] = data
	NeedsSystem.register_campeur(campeur_id)

	# Événement d'arrivée
	EventBus.emit("campeur.arrive", {
		"entite_id": campeur_id,
		"timestamp": SeasonManager.current_time,
		"prenom": data.prenom,
	})


func _exit_tree() -> void:
	if campeur_id == "":
		return  # Supprimé avant initialize() — rien à nettoyer

	NeedsSystem.unregister_campeur(campeur_id)
	if GameData.campeurs.has(campeur_id):
		GameData.campeurs.erase(campeur_id)

	EventBus.emit("campeur.depart", {
		"entite_id": campeur_id,
		"timestamp": SeasonManager.current_time,
	})


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[DEBUG] Campeur cliqué : " + campeur_id)
