extends Node

@onready var menu: Control = $Menu
@onready var game: Node2D = $Game
@onready var board: Node2D = $Game/Board

func _ready():
	game.visible = false
	menu.connect("game_started", Callable(self, "_on_game_started"))
	board.connect("lobby_menu_requested", Callable(self, "_on_exit_requested"))
	
func _on_game_started():
	menu.visible = false
	game.visible = true

func _on_exit_requested():
	Networking.send_leave_game()
	game.visible = false
	menu.visible = true
	menu.return_to_lobby()
