extends ColorRect
class_name BoardTile

@export var tile_name: String = ""
@export var is_dark: bool
var highlight: ColorRect
var move_indicator: Control

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(4, size.y - 4), tile_name,HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE if is_dark else Color.BLACK)

func _ready():
	name = tile_name
	color = Color(0.4, 0.3, 0.2) if is_dark else Color(0.9, 0.9, 0.9)
	highlight = ColorRect.new()
	highlight.color = Color(1.0, 0.85, 0.2, 0.6)
	highlight.visible = false
	highlight.size = size
	add_child(highlight)
	
	move_indicator = MoveIndicator.new()
	move_indicator.size = size
	move_indicator.visible = false
	add_child(move_indicator)
	
	Store.connect("last_move_changed", Callable(self, "_on_last_move_changed"))
	Store.connect("highlight_moves", Callable(self, "_on_moves_changed"))

func _on_moves_changed(from_square: String, available_squares: Array):
	if tile_name.to_upper() in available_squares:
		# Verificar si hay una pieza enemiga en este casillero
		var has_enemy_piece = Store.board.get(tile_name, "") != "" and Store.board.get(tile_name, "") != "NONE"
		move_indicator.set_capture(has_enemy_piece)
		move_indicator.visible = true
	else:
		move_indicator.visible = false

func _on_last_move_changed(last_move: Dictionary):
	if last_move.has("from") and last_move.has("to"):
		if tile_name == last_move["from"] or tile_name == last_move["to"]:
			highlight.visible = true
		else:
			highlight.visible = false
	else:
		highlight.visible = false
