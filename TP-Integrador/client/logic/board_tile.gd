extends ColorRect
class_name BoardTile

@export var tile_name: String = ""
@export var base_color: Color
var highlight: ColorRect

func _ready():
	color = base_color
	highlight = ColorRect.new()
	highlight.color = Color(1.0, 0.85, 0.2, 0.6)
	highlight.visible = false
	highlight.size = size
	add_child(highlight)
	Store.connect("last_move_changed", Callable(self, "_on_last_move_changed"))
#	Store.connect("allowed_moves_changed", self, "_on_moves_changed")

func _on_moves_changed(moves: Array):
	highlight.visible = tile_name in moves


func _on_last_move_changed(last_move: Dictionary):
	if last_move.has("from") and last_move.has("to"):
		if tile_name == last_move["from"] or tile_name == last_move["to"]:
			highlight.visible = true
		else:
			highlight.visible = false
	else:
		highlight.visible = false
