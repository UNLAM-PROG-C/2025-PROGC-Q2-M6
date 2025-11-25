extends Node

@onready var menu: Control = $Menu
var game: Node2D
var board: Node2D
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var result_label: Label = $GameOverLayer/GameOverPanel/VBoxContainer/ResultLabel
@onready var back_to_menu_btn: Button = $GameOverLayer/GameOverPanel/VBoxContainer/BackToMenuBtn

func _ready():
	game_over_layer.visible = false
	menu.connect("left_game_ack", Callable(self,"_on_back_to_menu"))
	back_to_menu_btn.connect("pressed", Callable(self, "_on_back_to_menu"))
	call_deferred("_connect_store_signals")
	Networking.connect("joined_as_spectator", Callable(self, "_on_viewer_joined"))
	
func _connect_store_signals():
	Store.connect("game_over", Callable(self, "_on_game_over"))
	Store.connect("new_game_started", Callable(self, "_on_game_started"))

func _on_viewer_joined():
	Store.set_viewer()

func _on_game_started():
	if game:
		game.queue_free()
	game = preload("res://scenes/Game.tscn").instantiate()
	board = game.get_node("Board")
	add_child(game)
	menu.visible = false
	game.visible = true
	game_over_layer.visible = false

func _on_game_over(winner_color: Variant):
	var message := ""
	
	if Store.is_viewer:
		message = "Game ended."
  else:
	  if winner_color == null or winner_color == "":
		  message = "Draw!"
	  elif winner_color == Store.my_color:
		  message = "You Won!"
	  else:
		  message = "You Lost!"
	
	result_label.text = message
	
	call_deferred("_show_game_over_panel")

func _show_game_over_panel():
	game_over_layer.visible = true
	game_over_layer.show()

func _on_back_to_menu():
	game_over_layer.hide()

	if game:
		game.queue_free()
		game = null
		board = null

	menu.visible = true
	menu.reset_to_lobby()
	
	Store.clear()
