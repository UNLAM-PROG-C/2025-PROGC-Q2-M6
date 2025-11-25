extends Control
class_name MoveIndicator

const LINE_WIDTH := 4.0
const DIAMETER_RATIO := 0.3
const CAPTURE_DIAMETER_RATIO := 0.9

var is_capture := false

func _ready():
	mouse_filter = MOUSE_FILTER_IGNORE
	queue_redraw()

func set_capture(capture: bool):
	is_capture = capture
	queue_redraw()

func _draw():
	var tile_size = min(size.x, size.y)
	var center = Vector2(size.x / 2, size.y / 2)
	
	if is_capture:
		# Círculo en el borde para capturas
		var radius = (tile_size * CAPTURE_DIAMETER_RATIO) / 2.0
		_draw_circle_arc(center, radius, 0, TAU, Color(0.2, 0.2, 0.2, 0.5), LINE_WIDTH)
	else:
		# Círculo relleno en el centro para movimientos normales
		var radius = (tile_size * DIAMETER_RATIO) / 2.0
		draw_circle(center, radius, Color(0.2, 0.2, 0.2, 0.5))

func _draw_circle_arc(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color, width: float):
	var points_count := 32
	var points := PackedVector2Array()
	
	for i in range(points_count + 1):
		var angle := angle_from + i * (angle_to - angle_from) / points_count
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	for i in range(points_count):
		draw_line(points[i], points[i + 1], color, width, true)
