extends Node

@onready var menu: Control = $Menu
@onready var game: Node2D = $Game
@onready var board: Node2D = $Game/Board


func _ready():
	game.visible = false
	menu.connect("game_started", Callable(self, "_on_game_started"))
	menu.connect("back_to_lobby",Callable(self, "_on_back_to_loby"))
	board.connect("leave_game", Callable(self, "_on_leave_requested"))
	
func _on_game_started():
	menu.visible = false
	game.visible = true

func _on_leave_requested():
	Networking.send_leave_game()
	
func _on_back_to_loby():
	print("aqui")
	game.visible = false
	menu.visible = true
