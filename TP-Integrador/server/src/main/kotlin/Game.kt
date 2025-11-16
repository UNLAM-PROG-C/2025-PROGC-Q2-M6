import org.slf4j.LoggerFactory
import ch.qos.logback.classic.Level
import ch.qos.logback.classic.Logger
import org.eclipse.jetty.server.Server
import org.eclipse.jetty.servlet.ServletContextHandler
import org.eclipse.jetty.websocket.api.Session
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketClose
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketConnect
import org.eclipse.jetty.websocket.api.annotations.OnWebSocketMessage
import org.eclipse.jetty.websocket.server.config.JettyWebSocketServletContainerInitializer
import java.time.Duration
import java.util.UUID

class PlayerConnection {
    val id: String = UUID.randomUUID().toString()
    private var session: Session? = null

    @OnWebSocketConnect
    fun onConnect(session: Session) {
        this.session = session
        println("Player connected: $id")
        session.remote.sendString("""{"type": "connected", "payload": {"playerId": "$id"}}""")
    }

    @OnWebSocketClose
    fun onClose(statusCode: Int, reason: String?) {
        println("Player disconnected: $id; Reason: $reason; StatusCode: $statusCode")
    }

    @OnWebSocketMessage
    fun onMessage(message: String) {
        println("Received message from $id: $message")
        session?.remote?.sendString("message: $message")
    }
}

fun main(args: Array<String>) {
    (LoggerFactory.getLogger("org.eclipse.jetty") as Logger).level = Level.WARN
    (LoggerFactory.getLogger("org.eclipse.jetty.util.thread") as Logger).level = Level.WARN

    val cliPort = args
        .firstOrNull { it.startsWith("--port=") }
        ?.substringAfter("=")
        ?.toIntOrNull()
    val envPort = System.getenv("PORT")?.toIntOrNull()
    val port = cliPort ?: envPort ?: 3000

    val server = Server(port)

    val handler = ServletContextHandler(ServletContextHandler.SESSIONS)

    JettyWebSocketServletContainerInitializer.configure(handler) { _, container ->
        container.idleTimeout = Duration.ofDays(1)
        container.addMapping("/ws") { _, _ -> PlayerConnection() }
    }

    server.setHandler(handler)


    server.start()
    println("Server started on port $port")
    server.join()
}