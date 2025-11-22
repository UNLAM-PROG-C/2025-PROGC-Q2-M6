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

    val mapper = jacksonObjectMapper()

    fun handlePlayerJoin(player: Player): Boolean {
        if (players.size >= 2) {
            return false
        }
        players.add(player)
        if (players.size == 2) {
            broadcastState()
        }
        return true
    }

    fun handleSpectatorJoin(spectator: Spectator) {
        spectators.add(spectator)
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
        // Notify remaining player about the game over due to player leaving
        if (players.size == 1) {
            val remaining = players.first()
            val msg = """
            {   
                "type": "game_over", 
                "payload": {
                "winner": "${remaining.color}",
                "reason": "PLAYER_LEFT"
                }
            }
            """.trimIndent()

            // send to all sessions (players + spectators)
            val allSessions = players.map { it.session } + spectators.map { it.session }
            allSessions
                .filter { it.isOpen } 
                .forEach { session ->
                    try {
                        session.remote.sendString(msg)
                    } catch (_: Exception) { }
                }        
            return
        }
        // Remove the game from the store if no players and spectators are left
        if (players.isEmpty() && spectators.isEmpty()) {
            GameStore.games.remove(id)
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