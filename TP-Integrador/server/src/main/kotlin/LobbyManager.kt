import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArraySet
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper

object LobbyManager {
    // set thread-safe de PlayerConnection
    private val subscribers = CopyOnWriteArraySet<PlayerConnection>()

    private val mapper = jacksonObjectMapper()

    fun subscribe(player: PlayerConnection) {
        subscribers.add(player)
    }

    fun unsubscribe(player: PlayerConnection) {
        subscribers.remove(player)
    }

    fun sendGamesListTo(player: PlayerConnection) {
        val gamesInfo = GameStore.games.values.map { game ->
            mapOf(
                "id" to game.id,
                "players" to game.players.size,
                "spectators" to game.spectators.size
            )
        }

        val response = mapOf(
            "type" to "games_list",
            "payload" to mapOf("games" to gamesInfo)
        )

        // usar el helper de PlayerConnection para enviar
        player.send(response)
    }

    fun broadcastGamesList() {
        try {
            subscribers.forEach { sendGamesListTo(it) }
        } catch (e: Exception) {
            println("Failed to broadcast games list: ${e.message}")
        }
    }
}