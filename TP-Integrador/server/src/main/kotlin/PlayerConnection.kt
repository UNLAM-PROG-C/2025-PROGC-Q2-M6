@file:Suppress("unused")

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.KotlinModule
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.eclipse.jetty.websocket.api.Session
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketClose
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketConnect
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketMessage
import org.eclipse.jetty.websocket.api.annotations.WebSocket
import java.util.UUID

@WebSocket
class PlayerConnection {
    val id: String = UUID.randomUUID().toString()
    private var session: Session? = null
    private var isInGame: Boolean = false
    private var gameHandler: GameHandler? = null

    val mapper: ObjectMapper = jacksonObjectMapper()
        .registerModule(KotlinModule.Builder().build())
        .apply {
            addMixIn(WsMessage::class.java, WsMessageMixin::class.java)
        }

    @OnWebSocketConnect
    fun onConnect(session: Session) {
        this.session = session
        println("Player connected: $id")
        session.remote.sendString("""{"type": "connected", "payload": {"playerId": "$id"}}""")
    }

    @OnWebSocketClose
    fun onClose(statusCode: Int, reason: String?) {
        println("Player disconnected: $id")
    }

    @OnWebSocketMessage
    fun onMessage(session: Session, message: String) {
        println("Received message from $id: $message")
        val data = try {
            mapper.readValue(message, WsMessage::class.java)
        } catch (e: Exception) {
            println("Failed to parse message: ${e.message}")
            session.remote.sendString("""{"type": "error", "payload": "Invalid message format"}""")
            return
        }

        println(data)

        when (data) {
            is CreateGameMessage -> handleCreateGame()
            is JoinGameMessage -> handleJoinGame(data)
            is MakeMoveMessage -> handleMakeMove(data)
            is LeaveGameMessage -> handleLeaveGame()
            else -> {
                session.remote.sendString("""{"type": "error", "payload": "Unknown message type"}""")
            }
        }
    }

    fun handleCreateGame() {
        val game = GameStore.newGame()
        if (game.handlePlayerJoin(Player(id, session!!, "WHITE"))) {
            this.gameHandler = game
            this.isInGame = true
            session?.remote?.sendString("""{"type": "game_created", "payload": {"gameId": "${game.id}"}}""")
        } else {
            session?.remote?.sendString("""{"type": "error", "payload": "Failed to create game"}""")
        }
    }

    fun handleJoinGame(message: JoinGameMessage) {
        val gameId = message.payload.gameId
        val game = GameStore.getGame(gameId)
        /**
         * TODO: matchmaking workaround
         */
        if (game == null) {
            val firstGame = GameStore.games.values.find {
                it.players.size < 2
            }
            if (firstGame != null) {
                val player = Player(id, session!!, "BLACK")
                if (!firstGame.handlePlayerJoin(player)) {
                    session?.remote?.sendString("""{"type": "error", "payload": "Game is full"}""")
                    return
                }
                this.gameHandler = firstGame
                this.isInGame = true
                session?.remote?.sendString("""{"type": "joined_game", "payload": {"gameId": "${firstGame.id}"}}""")
                return
            }
            session?.remote?.sendString("""{"type": "error", "payload": "Game not found"}""")
            return
        }
        val player = Player(id, session!!, "BLACK")
        if (!game.handlePlayerJoin(player)) {
            session?.remote?.sendString("""{"type": "error", "payload": "Game is full"}""")
            return
        }
        this.gameHandler = game
        this.isInGame = true
        session?.remote?.sendString("""{"type": "joined_game", "payload": {"gameId": "${game.id}"}}""")
    }

    fun handleLeaveGame() {
        if (!isInGame || gameHandler == null) {
            session?.remote?.sendString("""{"type": "error", "payload": "Not in a game"}""")
            return
        }
        this.isInGame = false
        this.gameHandler = null
        session?.remote?.sendString("""{"type": "left_game", "payload": {}}""")
    }

    fun handleMakeMove(message: MakeMoveMessage) {
        if (!isInGame || gameHandler == null) {
            session?.remote?.sendString("""{"type": "error", "payload": "Not in a game"}""")
            return
        }
        val from = message.payload.from
        val to = message.payload.to
        val move = SimpleMove(from, to)
        gameHandler?.handleMove(move)?.let {
            if (!it) {
                session?.remote?.sendString("""{"type": "error", "payload": "Illegal move"}""")
                return
            }
        }
        session?.remote?.sendString("""{"type": "move_made", "payload": {"from": "$from", "to": "$to"}}""")
    }
}