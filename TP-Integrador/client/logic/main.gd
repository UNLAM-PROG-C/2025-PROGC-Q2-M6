extends Node

@onready var menu: Control = $Menu
@onready var game: Node2D = $Game
@onready var board: Node2D = $Game/Board


func _ready():
	game.visible = false
	menu.connect("game_started", Callable(self, "_on_game_started"))
	
func _on_game_started():
	menu.visible = false
	game.visible = true
	
func back_to_loby():
	game.visible = false
	menu.visible = true
