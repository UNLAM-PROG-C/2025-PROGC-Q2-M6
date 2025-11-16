import java.util.concurrent.ConcurrentHashMap

object GameStore {
    val games: MutableMap<String, GameHandler> = ConcurrentHashMap()

    fun newGame(): GameHandler {
        val game = GameHandler()
        games[game.id] = game;
        return game
    }

    fun getGame(gameId: String): GameHandler? {
        return games[gameId]
    }
}