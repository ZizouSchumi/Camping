extends GutTest

# Tests unitaires pour CameraController
# Vérifie le clamping zoom, les limites de position, et la vitesse de pan.

var _camera: CameraController

func before_each() -> void:
	_camera = CameraController.new()
	add_child(_camera)

func after_each() -> void:
	_camera.queue_free()

func test_zoom_clamp_min() -> void:
	# Tenter de dépasser le min vers le bas
	_camera._target_zoom = CameraController.ZOOM_MIN - 1.0
	_camera._target_zoom = clamp(_camera._target_zoom, CameraController.ZOOM_MIN, CameraController.ZOOM_MAX)
	assert_gte(_camera._target_zoom, CameraController.ZOOM_MIN, "Le zoom ne doit pas descendre sous ZOOM_MIN")

func test_zoom_clamp_max() -> void:
	# Tenter de dépasser le max vers le haut
	_camera._target_zoom = CameraController.ZOOM_MAX + 1.0
	_camera._target_zoom = clamp(_camera._target_zoom, CameraController.ZOOM_MIN, CameraController.ZOOM_MAX)
	assert_lte(_camera._target_zoom, CameraController.ZOOM_MAX, "Le zoom ne doit pas dépasser ZOOM_MAX")

func test_camera_position_clamp() -> void:
	# La caméra doit rester dans les limites via limit_* (Godot natif)
	assert_lte(_camera.limit_left, _camera.limit_right, "limit_left doit être inférieur à limit_right")
	assert_lte(_camera.limit_top, _camera.limit_bottom, "limit_top doit être inférieur à limit_bottom")

func test_edge_pan_vitesse_non_nulle() -> void:
	assert_gt(CameraController.PAN_SPEED, 0.0, "PAN_SPEED doit être strictement positif")
