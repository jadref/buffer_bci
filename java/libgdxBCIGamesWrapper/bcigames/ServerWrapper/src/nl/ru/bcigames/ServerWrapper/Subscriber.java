/*
 * Copyright (c) 2019 Jeremy Constantin Börker, Anna Gansen, Marit Hagens, Codruta Lugoj, Wouter Loeve, Samarpan Rai and Alex Tichter
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package nl.ru.bcigames.ServerWrapper;

import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.function.Function;

/**
 * A subscriber can listen to events send to the server.
 */
public class Subscriber implements Runnable{
    private ArrayList<SubscribeEvent> listeners;
    private ServerConnection connection;
    private boolean running = true;
    private ConnectionState state;
    private String hostname;
    private int port;
    private int timeout;
    private AsynchronousPublisher asynchPub;

    /**
     * Constructor to initialize the nl.ru.bcigames.serverwrapper.nl.ru.bcigames.ServerWrapper.Subscriber
     * @param hostname ip/hostname to connect to
     * @param port port to connect to
     * @param timeout time interval to ask for new events
     */
    public Subscriber(String hostname, int port, int timeout) {
        this.hostname = hostname;
        this.port = port;
        this.timeout = timeout;
        listeners = new ArrayList<>();
        state = ConnectionState.CLOSED;

    }

    /**
     * Sends an event to the server
     * @param key Represents the key/type of the event
     * @param value Actual value of the event
     */
    public void publish(String key, String value) {
        if(this.state == ConnectionState.CONNECTED) {
            asynchPub.add(key,value);
        }
    }

    /**
     * Sends an event to the server
     * @param key Represents the key/type of the event
     * @param value Actual value of the event
     */
    public void publish(String key, int[] value) {
        if(this.state == ConnectionState.CONNECTED){
            asynchPub.add(key, Arrays.toString(value));
        }
    }

    /**
     * Sends an event to the server
     * @param key Represents the key/type of the event
     * @param value Actual value of the event
     */
    public void publish(String key, int value) {
        if(this.state == ConnectionState.CONNECTED){
            asynchPub.add(key, Integer.toString(value));
        }
    }

    /**
     * Sends an event to the server
     * @param key Represents the key/type of the event
     * @param value Actual value of the event
     */
    public void publish(String key, double value) {
        asynchPub.add(key, Double.toString(value));
    }

    /**
     * Adds a custom predefined listener to the nl.ru.bcigames.serverwrapper.nl.ru.bcigames.ServerWrapper.Subscriber
     * @param subscribeEvent custom listener to add to the subscriber
     */
    public void addListener(SubscribeEvent subscribeEvent){
        listeners.add(subscribeEvent);
    }

    /**
     * Adds a listener with target key and target value to the nl.ru.bcigames.serverwrapper.nl.ru.bcigames.ServerWrapper.Subscriber
     * @param targetkey Key to listen to
     * @param targetvalue target event to listen to
     */
    public void addListener(String targetkey, String targetvalue){
        SubscribeEvent se = new SubscribeEvent() {
            @Override
            public boolean trigger(String key) {
                return key.equals(targetkey);
            }

            @Override
            public void action(String value) {
                if (value.equals(targetvalue)){
                    System.out.println("Target reached");
                    System.out.println("Text received " + value);
                }
            }
        };
        listeners.add(se);
    }

    /**
     * Adds a listener that listen to key events in form of an array
     * @param targetkey key to listen to under which the key events will get send
     */
    public void addKeyListener(String targetkey){
        SubscribeEvent se = new SubscribeEvent() {
            @Override
            public boolean trigger(String key) {
                return key.equals(targetkey);
            }

            @Override
            public void action(String value) {
                System.out.println("Key array received: " + value);
                int[] array = toIntArray(value);
                System.out.println(Arrays.toString(array));
            }
        };
        listeners.add(se);
    }


    /**
     * Wrapper to set up an nl.ru.bcigames.ServerWrapper.SubscribeEvent more easily.
     * Example usage: nl.ru.bcigames.ServerWrapper.Subscriber.addListenerWrapper("key", (targetValue) -> {System.out.println(targetValue);return "";});
     * @param targetkey the key to check for in the events
     * @param fun an anonymus function that decides what happens with the value of the message received
     */
    public void addListenerWrapper(String targetkey, Function<String, String> fun){
        SubscribeEvent se = new SubscribeEvent() {
            @Override
            public boolean trigger(String key) {
                return key.equals(targetkey);
            }
            @Override
            public void action(String value) {
                fun.apply(value);
            }
        };
        listeners.add(se);
    }

    /**
     * Stops all the listeners and empties the list.
     */
    public void stopListeners(){
        listeners = new ArrayList<>();
    }

    /**
     * Returns whether or not the client is connected to the server
     * @return if it is connected or not
     */
    public boolean isConnected(){
        if (this.state == ConnectionState.CONNECTED)
            return true;
        return false;
    }

    /**
     * Returns the state of the connection in a more explicit way
     * @return state of the connection
     */
    public ConnectionState getConnectionState() {
        if(connection != null) {
            return connection.getState();
        }
        else {
            return state;
        }
    }

    /**
     * Safely disconnects the nl.ru.bcigames.serverwrapper.nl.ru.bcigames.ServerWrapper.Subscriber from the server.
     */
    public void disconnect() {
        this.state = ConnectionState.CLOSED;
        stopListeners();
        running = false;
        //connection.disconnect();
        asynchPub.stop();
    }

    /**
     * Because the server only can send strings, the string needs to be converted back into an int array
     * @param input String form of int array
     * @return int array
     */
    public static int[] toIntArray(String input) {
        String beforeSplit = input.replaceAll("\\[|\\]|\\s", "");
        String[] split = beforeSplit.split("\\,");
        int[] result = new int[split.length];
        for (int i = 0; i < split.length; i++) {
            result[i] = Integer.parseInt(split[i]);
        }
        return result;
    }

    @Override
    public void run() {
        connection = new ServerConnection(hostname,port,timeout);
        connection.connect();
        asynchPub = new AsynchronousPublisher(connection);
        Thread t = new Thread(asynchPub);
        t.start();
        this.state = this.connection.getState();

        try {
            int nEvents = connection.getHeader().nEvents;
            System.out.println("Listener Thread running, nEvents = " + nEvents);
            // While running, fetch events.
            while (running) {
                this.state = this.connection.getState();

                // Check if there are new events.
                SamplesEventsCount sec = connection.getClient().waitForEvents(nEvents, connection.getTimeout());
                if (sec.nEvents > nEvents) {

                    // Fetch new events.
                    BufferEvent[] evts = connection.getClient().getEvents(nEvents, sec.nEvents - 1);
                    nEvents = sec.nEvents;

                    // Inform listeners
                    if(evts != null) {
                        for (BufferEvent e : evts) {
                            for (SubscribeEvent l : listeners) {
                                if (l.trigger(e.getType().toString()))
                                    l.action(e.getValue().toString());
                            }
                        }
                    }
                }
                Thread.sleep(100); // Let thread sleep for a short file to restrict amount of pull requests send to server
            }
        } catch (IOException ex) {
            System.out.println("Exception occurred when fetching events, quitting buffer event loop.");
            running = false;
            state = ConnectionState.CLOSED;
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
