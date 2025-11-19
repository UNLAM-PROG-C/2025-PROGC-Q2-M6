extends Node2D
class_name Board

@onready var tile_container: Node2D = $Tiles
@onready var piece_container: Node2D = $Pieces

const TILE_SIZE := 80
const TILE_SCENE := preload("res://BoardTile.tscn")
const FILES := ["a","b","c","d","e","f","g","h"]
const FILES := ["A","B","C","D","E","F","G","H"]
const RANKS := [8,7,6,5,4,3,2,1]
var tiles: Dictionary[String, BoardTile] = {}

var PIECE_TEXTURES := {
	"WHITE_PAWN": preload("res://sprites/pieces/white_pawn.svg"),
	"WHITE_KNIGHT": preload("res://sprites/pieces/white_knight.svg"),
	"WHITE_BISHOP": preload("res://sprites/pieces/white_bishop.svg"),
	"WHITE_ROOK": preload("res://sprites/pieces/white_rook.svg"),
	"WHITE_QUEEN": preload("res://sprites/pieces/white_queen.svg"),
	"WHITE_KING": preload("res://sprites/pieces/white_king.svg"),

	"BLACK_PAWN": preload("res://sprites/pieces/black_pawn.svg"),
	"BLACK_KNIGHT": preload("res://sprites/pieces/black_knight.svg"),
	"BLACK_BISHOP": preload("res://sprites/pieces/black_bishop.svg"),
	"BLACK_ROOK": preload("res://sprites/pieces/black_rook.svg"),
	"BLACK_QUEEN": preload("res://sprites/pieces/black_queen.svg"),
	"BLACK_KING": preload("res://sprites/pieces/black_king.svg"),
}

func _ready():
	_generate_board()
	call_deferred("_connect_store_signal")

func _connect_store_signal():
	Store.connect("board_changed", Callable(self, "_on_board_changed"))

func _generate_board():
	for r in range(8):
		for f in range(8):
			var tile := TILE_SCENE.instantiate()

			var is_dark := ((r + f) % 2 == 1)
			tile.base_color = Color(0.4, 0.3, 0.2) if is_dark else Color(0.9, 0.9, 0.9)

			var tileName := "%s%d" % [FILES[f], RANKS[r]]
			tile.tile_name = tileName

			tile.position = Vector2(f * TILE_SIZE, r * TILE_SIZE)
			tile.size = Vector2(TILE_SIZE, TILE_SIZE)

			tile_container.add_child(tile)
			tiles[tileName] = tile


func _on_board_changed(new_board: Dictionary):
	_redraw_pieces(new_board)


func _redraw_pieces(board: Dictionary):
	for c in piece_container.get_children():
		c.queue_free()

	for square in board.keys():
		var piece_name = board[square]
		if piece_name == "" or piece_name == null or piece_name == 'NONE':
			continue

		var sprite: TextureRect = PIECE_SCENE.instantiate()
		sprite.piece_name = piece_name
		sprite.texture = _get_piece_texture(piece_name)
		sprite.position = tiles[square].position
		
		sprite.set_stretch_mode(TextureRect.STRETCH_KEEP_CENTERED)
		sprite.set_size(Vector2(TILE_SIZE, TILE_SIZE))

		piece_container.add_child(sprite)




func _get_piece_texture(pieceName: String) -> Texture2D:
	# Name is uppercase ("WHITE_PAWN")
	return PIECE_TEXTURES.get(pieceName, null)


func get_square_from_pos(event_global_position: Vector2) -> String:
	for tile_key in tiles:
		var tile := tiles[tile_key]
		if tile.get_global_rect().has_point(event_global_position):
			return tile.tile_name
	return ""
	
func get_tile_position(square: String) -> Vector2:
	if tiles.has(square):
		return tiles[square].global_position #+ Vector2(TILE_SIZE/2, TILE_SIZE/2)
	return Vector2.ZERO