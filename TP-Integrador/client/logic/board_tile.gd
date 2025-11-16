extends ColorRect

@export var tile_name: String = ""
@export var base_color: Color
var highlight: ColorRect

func _ready():
	color = base_color
	highlight = ColorRect.new()
	highlight.color = Color(0,1,0,0.3)
	highlight.visible = false
	highlight.size = size
	add_child(highlight)
#	Store.connect("allowed_moves_changed", self, "_on_moves_changed")

func _on_moves_changed(moves: Array):
	highlight.visible = tile_name in moves
