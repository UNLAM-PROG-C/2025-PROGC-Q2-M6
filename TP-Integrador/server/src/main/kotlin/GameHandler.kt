import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.github.bhlangonijr.chesslib.Board
import com.github.bhlangonijr.chesslib.Piece
import utils.NoOpWriteCallback
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList

class GameHandler {
    val id: String = UUID.randomUUID().toString()
    val board: Board = Board()
    val players: MutableList<Player> = CopyOnWriteArrayList()
    val spectators: MutableList<Spectator> = CopyOnWriteArrayList()
    var lastMove: SimpleMove? = null;
    var gameEnded: Boolean = false 
    private set 

    // timestamp de última actividad (join, move, mensaje relevante)
    @Volatile
    var lastActivityMillis: Long = System.currentTimeMillis()
        private set

    private fun touch() {
        lastActivityMillis = System.currentTimeMillis()
    }


    val mapper = jacksonObjectMapper()

    fun handlePlayerJoin(player: Player): Boolean {
        if (players.size >= 2) {
            return false
        }
        players.add(player)
        touch() // actualizar última actividad
        if (players.size == 2) {
            broadcastState()
        }
        return true
    }

    fun handleSpectatorJoin(spectator: Spectator) {
        spectators.add(spectator)
        touch() // actualizar última actividad
        broadcastState()
    }

    fun handleMove(simpleMove: SimpleMove, playerId: String): Boolean {
        val currentPlayer = players.find { it.id == playerId }
        if (currentPlayer == null || currentPlayer.color != board.sideToMove.toString()) {
            return false
        }

        val promotion = getPromotionPiece(simpleMove)
        val moveToMake = simpleMove.toMove(promotion)

        if (!board.isMoveLegal(moveToMake, true)) {
            return false;
        }

        board.doMove(moveToMake)
        lastMove = simpleMove
        touch() // actualizar última actividad

        broadcastState()
        return true;
    }

    private fun getPromotionPiece(move: SimpleMove): Piece {
        val fullMove = move.toMove()
        val piece = board.getPiece(fullMove.from)
        val promotion = when (piece) {
            Piece.WHITE_PAWN if fullMove.to.rank.ordinal == 7 -> {
                Piece.WHITE_QUEEN
            }

            Piece.BLACK_PAWN if fullMove.to.rank.ordinal == 0 -> {
                Piece.BLACK_QUEEN
            }
            
            else -> {
                Piece.NONE
            }
        }
        
        return promotion
    }

    private fun buildGameState(): String {
        val isOver = board.isMated || board.isDraw
        val payload = mutableMapOf(
            "gameId" to id,
            "boardState" to board.boardToArray(),
            "allowedMoves" to board.legalMoves().map { move -> SimpleMove(move.from.toString(), move.to.toString()) },
            "playerTurn" to players.find { it.color == board.sideToMove.toString() }?.id,
            "gameOver" to (board.isMated || board.isDraw),
            "winner" to when {
                board.isMated -> if (board.sideToMove.toString() == "WHITE") "BLACK" else "WHITE"
                else -> null
            },
            "players" to players.associate { p -> p.id to mapOf("color" to p.color) },
        )
        lastMove?.let {
            payload["lastMove"] = mapOf(
                "from" to it.from,
                "to" to it.to
            )
        }

        if (isOver) {
            gameEnded = true
        }
        val stateMessage = mapOf(
            "type" to "game_state",
            "payload" to payload
        )
        return mapper.writeValueAsString(stateMessage)
    }
    
    // Handle player leaving the game
    fun handlePlayerLeave(playerId: String) {
        if (gameEnded) {
            return // No notificar si el juego ya terminó
        }
        if(spectators.find({ it.id == playerId }) != null) {
            // Eliminar espectador
            spectators.removeIf { it.id == playerId }
            return
        }
        // Eliminar jugador
        players.removeIf { it.id == playerId }
        
        // Notificar al resto (jugadores restantes + espectadores)
        if (players.size == 1) {
            val remaining = players.first()
            val opponentLeftMsg = mapOf(
                "type" to "opponent_left",
                "payload" to mapOf("playerId" to playerId)
            )
            val opponentLeftJson = try {
                mapper.writeValueAsString(opponentLeftMsg)
            } catch (e: Exception) {
                println("Failed to build opponent_left message: ${e.message}")
                null
            }
            
            opponentLeftJson?.let {
                try { remaining.session.remote.sendString(it) } catch (_: Exception) {}
            }
        }

        // --- Mensaje para los espectadores ---
        val spectatorMsg = mapOf(
            "type" to "player_left",
            "payload" to mapOf("playerId" to playerId)
        )
        val spectatorJson = try {
            mapper.writeValueAsString(spectatorMsg)
        } catch (e: Exception) {
            println("Failed to build spectator message: ${e.message}")
            null
        }

        spectatorJson?.let {
            spectators.mapNotNull { it.session }
                .filter { it.isOpen }
                .forEach { s ->
                    try { s.remote.sendString(it) } catch (_: Exception) {}
                }
        }
        // Si no quedan ni jugadores ni espectadores, eliminar la partida del store
        if (players.isEmpty() && spectators.isEmpty()) {
            try {
                GameStore.games.remove(id) 
            } catch (e: Exception) {
                println("Failed to remove game from store: ${e.message}")
            }

        }
        return
    }


    private fun broadcastState() {
        val stateMessage = buildGameState()
        println("Broadcasting game state: $stateMessage")
        val allSessions = players.map { it.session } + spectators.map { it.session }
        allSessions.filter { it.isOpen }.forEach { s ->
            try {
                s.remote.sendString(stateMessage, NoOpWriteCallback)
            } catch (_: Exception) {
            }
        }
    }
}