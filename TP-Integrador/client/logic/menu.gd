extends Control

signal game_started
signal left_game_ack

@onready var connect_panel: VBoxContainer = $ConnectPanel
@onready var server_url: LineEdit = $ConnectPanel/ServerURL
@onready var player_name: LineEdit = $ConnectPanel/PlayerName
@onready var connect_button: Button = $ConnectPanel/ConnectButton

@onready var lobby_panel: VBoxContainer = $LobbyPanel
@onready var create_button: Button = $LobbyPanel/CreateGameBtn
@onready var join_button: Button = $LobbyPanel/JoinGameBtn
@onready var cancel_button: Button = $LobbyPanel/CancelBtn

@onready var status_label: Label = $LobbyPanel/StatusLabel
@onready var game_list_panel: Control = $GameListPanel
@onready var board: Board = get_node("/root/Main/Game/Board")


func _ready():
	lobby_panel.visible = false
	game_list_panel.visible = false
	cancel_button.visible = false
	
	connect_button.connect("pressed", Callable(self, "_on_ConnectButton_pressed"))
	create_button.connect("pressed", Callable(self, "_on_CreateButton_pressed"))
	cancel_button.connect("pressed", Callable(self,"_on_leave_game"))
	join_button.connect("pressed", Callable(self, "_on_JoinButton_pressed"))
	game_list_panel.connect("join_game_requested", Callable(self, "_on_game_selected"))
	game_list_panel.connect("back_pressed", Callable(self, "_on_back_from_list"))
	game_list_panel.connect("refresh_pressed", Callable(self, "_on_refresh_list"))
	board.connect("leave_game", Callable(self, "_on_leave_game"))
	
	# --- Networking signals ---
	Networking.connect("connected", Callable(self, "_on_connected"))
	Networking.connect("connection_failed", Callable(self, "_on_connection_failed"))
	Networking.connect("game_created", Callable(self, "_on_game_created"))
	Networking.connect("joined_game", Callable(self, "_on_joined_game"))
	Networking.connect("game_state", Callable(self, "_on_game_state"))
	Networking.connect("error_received", Callable(self, "_on_error"))
	Networking.connect("games_list", Callable(self, "_on_games_list"))
	Networking.connect("left_game", Callable(self, "_on_left_game"))
	
func reset_to_lobby():
	# Resetear todos los paneles y botones al estado inicial del lobby
	connect_panel.visible = false
	lobby_panel.visible = true
	game_list_panel.visible = false
	
	create_button.disabled = false
	join_button.disabled = false
	cancel_button.visible = false
	
	status_label.text = ""

func _on_ConnectButton_pressed():
	var url = server_url.text.trim_suffix(" ")
	var playerName = player_name.text.strip_edges()

	if url.is_empty() or playerName.is_empty():
		status_label.text = "Enter server URL + name."
		return

	status_label.text = "Connecting..."

	Networking.connect_ws(url)
	Store.clear()
	Store.my_color = ""
	Store.game_id = ""


func _on_connected(player_id):
	status_label.text = "Connected as %s" % player_id
	connect_panel.visible = false
	lobby_panel.visible = true


func _on_connection_failed(reason):
	status_label.text = "Connection failed: " + str(reason)


#
# --- STEP 2A: CREATE GAME ---
#

func _on_CreateButton_pressed():
	status_label.text = "Creating game..."
	Networking.send_create_game()


func _on_game_created(game_id):
	status_label.text = "Game created.\nWaiting for opponent...\nGame ID: %s" % game_id
	# Deshabilitar botón de crear/join
	create_button.disabled = true
	join_button.disabled = true
	#cancel visible 
	cancel_button.visible = true
	

#
# --- STEP 2B: JOIN GAME ---
#

func _on_JoinButton_pressed():
	lobby_panel.visible = false
	game_list_panel.visible = true
	# pedir lista de partida
	Networking.send_list_games()



func _on_refresh_list():
	Networking.send_list_games()


func _on_games_list(payload):
	var games = payload.get("games", [])
	game_list_panel.populate(games)
#
# --- STEP 3: JOINED GAME ---
#

func _on_joined_game(game_id):
	# volvemos a ocultar todo y esperar el game_state
	connect_panel.visible = false
	lobby_panel.visible = false
	game_list_panel.visible = false
#
# --- STEP 4: GAME STATE ARRIVES => START GAME ---
#

func _on_game_state(payload):
	# The very first game_state means:
	# - Both players are in the game
	# - Board is ready
	# - Game can start
	Store.apply_state(payload)

	emit_signal("game_started")

func _on_game_selected(game_id):
	game_list_panel.visible = false
	lobby_panel.visible = false
	status_label.text = "Joining game %s..." % game_id
	Networking.send_join_game(game_id)

func _on_back_from_list():
	game_list_panel.visible = false
	lobby_panel.visible = true

# leave game request due cancel or opponent left
func _on_leave_game():
	Networking.send_leave_game()

# left game confirmation signal from server and send signal
func _on_left_game():
	emit_signal("left_game_ack")	
#	
# --- ERRORS ---
#
	
func _on_error(msg):
	status_label.text = "Error: " + str(msg)
	
	
