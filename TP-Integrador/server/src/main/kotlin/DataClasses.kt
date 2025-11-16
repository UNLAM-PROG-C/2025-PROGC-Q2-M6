import com.github.bhlangonijr.chesslib.Square
import com.github.bhlangonijr.chesslib.move.Move
import org.eclipse.jetty.websocket.api.Session

class SimpleMove(val from: String, val to: String) {
    fun toMove(): Move {
        return Move(Square.valueOf(from), Square.valueOf(to))
    }
}
data class Player(val id: String, val session: Session, val color: String)
data class Spectator(val id: String, val session: Session)
