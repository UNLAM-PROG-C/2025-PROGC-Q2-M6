import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

object GameStore {
    val games: MutableMap<String, GameHandler> = ConcurrentHashMap()
    
    private val cleaner: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor()
    private const val CLEAN_INTERVAL_SECONDS: Long = 60      // cada 60s
    private val STALE_THRESHOLD_MS: Long = TimeUnit.MINUTES.toMillis(30) // 30 minutos
    
    fun newGame(): GameHandler {
        val game = GameHandler()
        games[game.id] = game;
        return game
    }

    fun getGame(gameId: String): GameHandler? {
        return games[gameId]
    }

    fun startCleaner() {
        cleaner.scheduleAtFixedRate({
            try {
                val now = System.currentTimeMillis()
                val toRemove = mutableListOf<String>()
                for ((id, game) in games) {
                    val last = try { game.lastActivityMillis } catch (e: Exception) { 0L }
                    // eliminar si vacío o inactivo por más del umbral
                    if ((game.players.isEmpty() && game.spectators.isEmpty()) || (now - last) > STALE_THRESHOLD_MS) {
                        toRemove.add(id)
                    }
                }
                toRemove.forEach { id ->
                    games.remove(id)
                    println("Cleaner removed game: $id")
                }
            } catch (e: Exception) {
                println("GameStore cleaner error: ${e.message}")
            }
        }, CLEAN_INTERVAL_SECONDS, CLEAN_INTERVAL_SECONDS, TimeUnit.SECONDS)
    }

    fun stopCleaner() {
        try { cleaner.shutdownNow() } catch (_: Exception) {}
    }

}