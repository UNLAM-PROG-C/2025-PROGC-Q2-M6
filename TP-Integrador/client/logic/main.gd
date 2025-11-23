extends Node

@onready var menu: Control = $Menu
@onready var game: Node2D = $Game
@onready var board: Node2D = $Game/Board
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var result_label: Label = $GameOverLayer/GameOverPanel/VBoxContainer/ResultLabel
@onready var back_to_menu_btn: Button = $GameOverLayer/GameOverPanel/VBoxContainer/BackToMenuBtn

func _ready():
	game.visible = false
	game_over_layer.visible = false
	menu.connect("game_started", Callable(self, "_on_game_started"))
	menu.connect("left_game_ack", Callable(self,"_on_back_to_menu"))
	back_to_menu_btn.connect("pressed", Callable(self, "_on_back_to_menu"))
	call_deferred("_connect_store_signals")

func _connect_store_signals():
	Store.connect("game_over", Callable(self, "_on_game_over"))
	print("Connected to Store.game_over signal")
	
func _on_game_started():
	menu.visible = false
	game.visible = true
	game_over_layer.visible = false

func _on_game_over(winner_color: Variant):
	print("Game over called! Winner: ", winner_color, " My color: ", Store.my_color)
	
	var message = ""
	
	if winner_color == null or winner_color == "":
		message = "Draw!"
	elif winner_color == Store.my_color:
		message = "You Won!"
	else:
		message = "You Lost!"
	
	print("Showing message: ", message)
	result_label.text = message
	
	call_deferred("_show_game_over_panel")

func _show_game_over_panel():
	game_over_layer.visible = true
	game_over_layer.show()
	print("Panel should be visible now")

func _on_back_to_menu():
	print("Returning to menu...")
	
	game_over_layer.visible = false
	game.visible = false
	
	menu.visible = true
	menu.reset_to_lobby()
	
	Store.clear()
		
	print("Back to menu complete")
