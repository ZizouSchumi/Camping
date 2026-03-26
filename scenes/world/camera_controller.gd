extends Camera2D
class_name CameraController

# Système caméra — Pan (bords + drag molette), Zoom (molette + interpolation)
# Toutes les entrées passent par l'InputMap, jamais de keycodes directs.

const PAN_SPEED: float = 400.0
const PAN_EDGE_MARGIN: float = 20.0
const ZOOM_SPEED: float = 0.1
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 3.0
const ZOOM_LERP_SPEED: float = 10.0

var _target_zoom: float = 1.0
var _is_dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	_process_edge_pan(delta)
	_process_zoom_interpolation(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_MIDDLE:
				_is_dragging = mb.pressed
				if _is_dragging:
					_drag_start = mb.position
			MOUSE_BUTTON_WHEEL_UP:
				_target_zoom = clamp(_target_zoom - ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)
			MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom = clamp(_target_zoom + ZOOM_SPEED, ZOOM_MIN, ZOOM_MAX)

	elif event is InputEventMouseMotion and _is_dragging:
		var motion := event as InputEventMouseMotion
		position -= motion.relative / zoom.x


func _process_edge_pan(delta: float) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var direction: Vector2 = Vector2.ZERO

	if mouse_pos.x < PAN_EDGE_MARGIN:
		direction.x = -1.0
	elif mouse_pos.x > viewport_size.x - PAN_EDGE_MARGIN:
		direction.x = 1.0
	if mouse_pos.y < PAN_EDGE_MARGIN:
		direction.y = -1.0
	elif mouse_pos.y > viewport_size.y - PAN_EDGE_MARGIN:
		direction.y = 1.0

	if direction != Vector2.ZERO:
		position += direction * PAN_SPEED * delta


func _process_zoom_interpolation(delta: float) -> void:
	var new_zoom: float = zoom.x + (_target_zoom - zoom.x) * ZOOM_LERP_SPEED * delta
	zoom = Vector2(new_zoom, new_zoom)
