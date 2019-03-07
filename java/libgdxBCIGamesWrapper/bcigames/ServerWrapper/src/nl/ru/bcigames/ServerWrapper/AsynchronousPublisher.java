package nl.ru.bcigames.ServerWrapper;

import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;

import java.io.IOException;
import java.util.ArrayList;

/**
 * Putting events in a queue before sending them to the server.
 */
public class AsynchronousPublisher implements Runnable {

    private ArrayList<Pair> queue = new ArrayList<Pair>();
    private ServerConnection connection;
    private Boolean running;

    public AsynchronousPublisher(ServerConnection connection){
        this.connection = connection;
    }

    /**
     * sending events from the queue to the server
     */
    @Override
    public void run() {
        running = true;
        while(running) {
            if (!queue.isEmpty()) {
                if(connection.isConnected()) {
                    Pair p = queue.get(0);
                    queue.remove(0);
                    try {
                        connection.getClient().putEvent(new BufferEvent(p.getKey(), p.getValue(), -1));
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }

            try {
                Thread.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Add an event to the queue
     * @param key of the event
     * @param value of the event
     */
    public void add(String key, String value){
        queue.add(new Pair(key, value));
    }

    /**
     * Stops the publisher
     */
    public void stop(){
        running = false;
        connection.disconnect();
    }

    /**
     * Data structure to store the messages
     */
    private static class Pair {
        private String key;
        private String value;

        public Pair(String key, String value){
            this.key = key;
            this.value = value;
        }

        public String getKey(){
            return key;
        }

        public String getValue(){
            return value;
        }
    }


}
