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
        )
        lastMove?.let {
            payload["lastMove"] = mapOf(
                "from" to it.from,
                "to" to it.to
            )
        }
        val stateMessage = mapOf(
            "type" to "game_state",
            "payload" to payload
        )
        return mapper.writeValueAsString(stateMessage)
    }
    
    // Handle player leaving the game
    fun handlePlayerLeave(playerId: String) {
        players.removeIf { it.id == playerId }
        
        // Notificar al resto (jugadores restantes + espectadores)
        if (players.size == 1) {
            val remaining = players.first()
            val gameOverMsg = mapOf(
                "type" to "opponent_left",
                "payload" to mapOf("playerId" to playerId)
            )
            val gameOverJson = try {
                mapper.writeValueAsString(gameOverMsg)
            } catch (e: Exception) {
                println("Failed to build game_over message: ${e.message}")
                null
            }
            //
            gameOverJson?.let {
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