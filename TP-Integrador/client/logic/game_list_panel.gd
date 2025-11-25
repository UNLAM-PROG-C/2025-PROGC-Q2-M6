extends Panel

signal back_pressed()
signal refresh_pressed()
signal join_game_requested(game_id)
signal join_game_viewer(game_id)

const GAME_ROW_SCENE := preload("res://scenes/GameRow.tscn")
@export var game_row_scene: PackedScene
@onready var rows_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/RowsContainer
@onready var back_btn = $MarginContainer/VBoxContainer/HBoxContainer/Back
@onready var refresh_btn = $MarginContainer/VBoxContainer/HBoxContainer/Refresh

func _ready():
	back_btn.connect("pressed", Callable(self, "_on_back"))
	refresh_btn.connect("pressed", Callable(self, "_on_refresh"))

	
func populate(games):
	#print("DEBUG populate() games=", games)
	 # Borrar todo inmediatamente
	for c in rows_container.get_children():
		c.free()  
	if games.is_empty():
		#print("DEBUG: games vacío, agregando label")
		var lbl := Label.new()
		lbl.text = "No games available"
		rows_container.add_child(lbl)
		return
	#print("DEBUG: agregando filas")
	for game in games:
		var row = game_row_scene.instantiate()
		row.setup({
			"id": game.get("id", ""),
			"players": int(game.get("players", 0)),
			"spectators": int(game.get("spectators", 0))
			})
		row.connect("join_pressed", Callable(self, "_on_row_join"))
		row.connect("viewer_pressed",Callable(self,"_on_row_viewer_join"))
		rows_container.add_child(row)

func _on_row_join(game_id):
	emit_signal("join_game_requested", game_id)
	
func _on_row_viewer_join(game_id):
	emit_signal("join_game_viewer", game_id)
	
func _on_back():
	emit_signal("back_pressed")

func _on_refresh():
	emit_signal("refresh_pressed")
