extends Node

signal state_changed
signal board_changed(board)
signal allowed_moves_changed(highlights)
signal turn_changed(player_id)
signal game_over(winner_color)
signal last_move_changed(last_move)
signal new_game_started()
signal highlight_moves(from_square, available_squares)

var game_id: String
var board: Dictionary = {}
var allowed_moves: Array = []
var player_turn: String = ""
var game_is_over: bool = false
var winner_color: Variant = ""
var my_color: String = ""
var last_move: Dictionary = {}

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
	last_move = payload.get("lastMove", {})

	board = _array_to_map(payload.boardState)
	
	my_color = payload.players[Networking.player_id].get("color", "")
	

	emit_signal("board_changed", board)
	emit_signal("allowed_moves_changed", _highlight_tiles(allowed_moves))
	emit_signal("turn_changed", player_turn)
	emit_signal("state_changed")
	emit_signal("last_move_changed", last_move)
	
	
	if last_move.is_empty():
		emit_signal("new_game_started")

	if game_is_over:
		print("Store: Game is over! Winner: ", winner_color)
		emit_signal("game_over", winner_color)


func _array_to_map(arr: Array) -> Dictionary:
	var map := {}
	var files: Array[Variant] = ["A","B","C","D","E","F","G","H"]
	var ranks: Array[Variant] = [1,2,3,4,5,6,7,8]
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

func try_move(from: String, to: String) -> bool:
	if player_turn != Networking.player_id:
		print("Not your turn!")
		return false
	
	var from_up := from.to_upper()
	var to_up := to.to_upper()
	for m in allowed_moves:
		var mf := String(m.get("from", "")).to_upper()
		var mt := String(m.get("to", "")).to_upper()
		if mf == from_up and mt == to_up:
			return true
	return false

func is_my_turn() -> bool:
	return player_turn == Networking.player_id

func highlight_from(square: String):
	var from_up := square.to_upper()
	var available := []
	
	for m in allowed_moves:
		var mf := String(m.get("from", "")).to_upper()
		if mf == from_up:
			var mt := String(m.get("to", "")).to_upper()
			available.append(mt)
	
	emit_signal("highlight_moves", from_up, available)

func clear_highlights():
	emit_signal("highlight_moves", "", [])
