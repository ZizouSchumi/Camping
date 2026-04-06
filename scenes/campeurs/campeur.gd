class_name Campeur extends CharacterBody2D

# campeur.gd — Entité PNJ campeur.
# Utiliser initialize(data) après add_child() — NE PAS appeler dans _ready().
# Le pathfinding A* (GridSystem) est actif depuis S2.4.
# NavigationAgent2D reste inactif jusqu'à S2.5 (collision avoidance dynamique).

const MOVE_SPEED: float = 80.0      # pixels par seconde de temps réel
const ARRIVE_THRESHOLD: float = 4.0  # distance en px pour considérer un waypoint atteint

var campeur_id: String = ""
var _data: CampeurData = null
var _path: Array[Vector2i] = []
var _path_index: int = 0


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
	_data.world_position = spawn_position  # Sync immédiat — évite fausse rencontre au frame 0

	# Mise à jour visuelle
	$Label.text = data.prenom

	# Enregistrement dans les systèmes globaux
	GameData.campeurs[campeur_id] = data
	NeedsSystem.register_campeur(campeur_id)
	EventBus.subscribe("campeur.deplacer_vers", _on_deplacer_vers)
	$EmoteDisplay.setup(campeur_id)

	# Événement d'arrivée
	EventBus.emit("campeur.arrive", {
		"entite_id": campeur_id,
		"timestamp": SeasonManager.current_time,
		"prenom": data.prenom,
	})


func move_to(target_world_pos: Vector2) -> void:
	if campeur_id == "":
		return  # Pas encore initialisé
	var from_grid := GridSystem.world_to_grid(position)
	var to_grid := GridSystem.world_to_grid(target_world_pos)
	var new_path := GridSystem.find_path(from_grid, to_grid)
	if new_path.is_empty():
		push_warning("Campeur.move_to: aucun chemin vers " + str(to_grid) + " depuis " + str(from_grid))
		return
	_path = new_path
	_path_index = 0


func _physics_process(_delta: float) -> void:
	if _data != null:
		_data.world_position = position
	if SeasonManager.paused or _path.is_empty() or _path_index >= _path.size():
		velocity = Vector2.ZERO
		return
	var cell_world := GridSystem.grid_to_world(_path[_path_index])
	var waypoint := cell_world + Vector2(GridSystem.CELL_SIZE * 0.5, GridSystem.CELL_SIZE * 0.5)
	if position.distance_to(waypoint) <= ARRIVE_THRESHOLD:
		_path_index += 1
		if _path_index >= _path.size():
			_path = []
			velocity = Vector2.ZERO
			EventBus.emit("campeur.destination_atteinte", {
				"entite_id": campeur_id,
				"timestamp": SeasonManager.current_time,
				"position": position,
			})
		return
	velocity = position.direction_to(waypoint) * MOVE_SPEED * SeasonManager.time_scale
	move_and_slide()


func _exit_tree() -> void:
	if campeur_id == "":
		return  # Supprimé avant initialize() — rien à nettoyer

	EventBus.unsubscribe("campeur.deplacer_vers", _on_deplacer_vers)
	NeedsSystem.unregister_campeur(campeur_id)
	if GameData.campeurs.has(campeur_id):
		GameData.campeurs.erase(campeur_id)

	EventBus.emit("campeur.depart", {
		"entite_id": campeur_id,
		"timestamp": SeasonManager.current_time,
	})


func _on_deplacer_vers(payload: Dictionary) -> void:
	if payload.get("entite_id", "") != campeur_id:
		return
	move_to(payload.get("position", Vector2.ZERO))


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		UIManager.open("campeur_fiche", {"campeur_id": campeur_id})
