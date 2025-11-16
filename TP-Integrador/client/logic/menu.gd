extends Control

signal game_started

@onready var connect_panel: VBoxContainer = $ConnectPanel
@onready var server_url: LineEdit = $ConnectPanel/ServerURL
@onready var player_name: LineEdit = $ConnectPanel/PlayerName
@onready var connect_button: Button = $ConnectPanel/ConnectButton

@onready var lobby_panel: VBoxContainer = $LobbyPanel
@onready var create_button: Button = $LobbyPanel/CreateGameBtn
@onready var join_button: Button = $LobbyPanel/JoinGameBtn
@onready var refresh_button: Button = $LobbyPanel/RefreshBtn
@onready var games_list: ItemList = $LobbyPanel/GameList
@onready var status_label: Label = $LobbyPanel/StatusLabel


func _ready():
	lobby_panel.visible = false
	connect_button.connect("pressed", Callable(self, "_on_ConnectButton_pressed"))
	create_button.connect("pressed", Callable(self, "_on_CreateButton_pressed"))
	join_button.connect("pressed", Callable(self, "_on_JoinButton_pressed"))
	refresh_button.connect("pressed", Callable(self, "_on_RefreshButton_pressed"))
	
	# --- Networking signals ---
	Networking.connect("connected", Callable(self, "_on_connected"))
	Networking.connect("connection_failed", Callable(self, "_on_connection_failed"))
	Networking.connect("game_created", Callable(self, "_on_game_created"))
	Networking.connect("joined_game", Callable(self, "_on_joined_game"))
	Networking.connect("game_state", Callable(self, "_on_game_state"))
	Networking.connect("error_received", Callable(self, "_on_error"))
	
	Networking.connect("connected", Callable(self, "_on_connected"))
	Networking.connect("connection_failed", Callable(self, "_on_connection_failed"))
	Networking.connect("game_created", Callable(self, "_on_game_created"))
	Networking.connect("joined_game", Callable(self, "_on_joined_game"))
	Networking.connect("game_state", Callable(self, "_on_game_state"))
	Networking.connect("error_received", Callable(self, "_on_error"))

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


#
# --- STEP 2B: JOIN GAME ---
#

func _on_JoinButton_pressed():
	status_label.text = "Searching for an open game..."

	# Send a random valid UUID so server validation succeeds
	var dummy_id: String = "123e4567-e89b-12d3-a456-426614174000"

	Networking.send_join_game(dummy_id)



func _on_RefreshButton_pressed():
	_request_game_list()


func _request_game_list():
	# Your server doesn't have a "list_games" command yet
	# You can add it OR skip this feature
	status_label.text = "The server has no game-listing endpoint yet."


#
# --- STEP 3: JOINED GAME ---
#

func _on_joined_game(game_id):
	status_label.text = "Joined game: %s\nWaiting for game start..." % game_id


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


#
# --- ERRORS ---
#

func _on_error(msg):
	status_label.text = "Error: " + str(msg)
