extends Node

signal state_changed
signal board_changed(board)
signal allowed_moves_changed(highlights)
signal turn_changed(player_id)
signal game_over(winner_color)
signal my_color_changed(color)

var game_id: String
var board: Dictionary = {}
var allowed_moves: Array = []
var player_turn: String = ""
var game_is_over: bool = false
var winner_color: Variant = ""
var my_color: String = ""

func clear():
	game_id = ""
	board.clear()
	allowed_moves.clear()
	player_turn = ""
	game_is_over = false
	winner_color = ""
	my_color = ""


func apply_state(payload: Dictionary):
	game_id = payload.gameId
	allowed_moves = payload.allowedMoves
	player_turn = payload.playerTurn
	game_is_over = payload.gameOver
	winner_color = payload.get("winner")

	board = _array_to_map(payload.boardState)

	# Determine whether *you* are white or black
	if my_color == "" and player_turn != "":
		if player_turn == Networking.player_id:
			my_color = "WHITE"
		else:
			my_color = "BLACK"
		emit_signal("my_color_changed", my_color)

	emit_signal("board_changed", board)
	emit_signal("allowed_moves_changed", _highlight_tiles(allowed_moves))
	emit_signal("turn_changed", player_turn)
	emit_signal("state_changed")

	if game_is_over:
		emit_signal("game_over", winner_color)


func _array_to_map(arr: Array) -> Dictionary:
	var map := {}
	var files: Array[Variant] = ["a","b","c","d","e","f","g","h"]
	var ranks: Array[Variant] = [8,7,6,5,4,3,2,1]
	var i: int = 0

	for r in ranks:
		for f in files:
			var sq: String = "%s%d" % [f,r]
			var val = arr[i]
			map[sq] = val if val != null else ""
			i += 1

	return map


func _highlight_tiles(moves: Array) -> Array:
	var result := []
	for m in moves:
		if m.has("to"):
			result.append(m.to)
	return result
