package nl.ru.dcc.buffer_bci.screens;
import java.io.IOException;
import nl.fcdonders.fieldtrip.bufferclient.*;

public class ConnectingScreen extends InstructScreen {
    BufferClientClock client;
    public String host;
    public int port;
    float timeSinceAction;
    public static final float RECONNECTINTERVAL=1;

    public ConnectingScreen(BufferClientClock client, String host, int port) {
        super("Connecting to server\n\n\n(Press to continue in disconnected mode)");
        this.client = client;
        this.host = host;
        this.port = port;
        timeSinceAction =0;
        setDuration(30000);
    }
    public ConnectingScreen(BufferClientClock client) { this(client,"localhost",1972); }

    @Override
    public void update(float delta) {
        timeSinceAction += delta;
        if ( client != null && !client.isConnected() ) {
            if (timeSinceAction > RECONNECTINTERVAL) {
                timeSinceAction = 0;
                try {
                    client.connect(host, port);
                } catch (IOException ex) {
                    setInstruction("Couldn't connect to server " + host + ":" + port + " ... waiting\n\n");
                }
            }
            if (client.isConnected()) {
                setInstruction("Connected " + host + ":" + port + "!");
                setDuration_ms((int)(getTimeSpent_ms() + 1000)); // set to run the heartbeat set
                timeSinceAction=0;
                // Sync buffer clock with amplifier sample clock
                try {
                    client.syncClocks(new int[]{0,100,100,100,100,100,100,100,100,100,100});
                } catch ( IOException ex ) {
                    log("CONNECTING","failed in clock sync");
                }
            }
        }
    }
}
