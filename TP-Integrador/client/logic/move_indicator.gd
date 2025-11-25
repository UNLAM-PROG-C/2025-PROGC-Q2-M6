extends Control
class_name MoveIndicator

const LINE_WIDTH := 6
const DIAMETER_RATIO := 0.75

const circle_color := Color(0,0,0,0.6)

var is_capture := false

func _ready():
	mouse_filter = MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw():
	var tile_size = min(size.x, size.y)
	var center := Vector2(size.x / 2, size.y / 2)
	var radius = (tile_size * DIAMETER_RATIO) / 2.0
	
	draw_arc(center, radius, 0, TAU, 128, circle_color, LINE_WIDTH)
