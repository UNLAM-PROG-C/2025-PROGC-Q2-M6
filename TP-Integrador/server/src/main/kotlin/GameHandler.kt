import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.github.bhlangonijr.chesslib.Board
import utils.NoOpWriteCallback
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList

class GameHandler {
    val id: String = UUID.randomUUID().toString()
    val board: Board = Board()
    val players: MutableList<Player> = CopyOnWriteArrayList()
    val spectators: MutableList<Spectator> = CopyOnWriteArrayList()

    val mapper = jacksonObjectMapper()

    fun handlePlayerJoin(player: Player): Boolean {
        if (players.size >= 2) {
            return false
        }
        players.add(player)
        if(players.size == 2) {
            broadcastState()
        }
        return true
    }

    fun handleSpectatorJoin(spectator: Spectator) {
        spectators.add(spectator)
        broadcastState()
    }

    fun handleMove(move: SimpleMove): Boolean {
        if (!board.isMoveLegal(move.toMove(), true)) {
            return false;
        }

        board.doMove(move.toMove())

        broadcastState()
        return true;
    }

    private fun buildGameState(): String {
        val stateMessage = mapOf(
            "type" to "game_state",
            "payload" to mapOf(
                "gameId" to id,
                "boardState" to board.boardToArray(),
                "allowedMoves" to board.legalMoves().map { move -> SimpleMove(move.from.toString(), move.to.toString()) },
                "playerTurn" to players.find { it.color == board.sideToMove.toString() }?.id,
                "gameOver" to (board.isMated || board.isDraw),
                "winner" to when {
                    board.isMated -> if (board.sideToMove.toString() == "WHITE") "BLACK" else "WHITE"
                    else -> null
                }
            )
        )
        return mapper.writeValueAsString(stateMessage)
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