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

import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.BufferClientClock;
import nl.fcdonders.fieldtrip.bufferclient.Header;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * Handles the specific logic of a connection to the server.
 * nl.ru.bcigames.serverwrapper.nl.ru.bcigames.ServerWrapper.Subscriber build upon that class.
 */
public class ServerConnection {
    private BufferClientClock client = new BufferClientClock();
    private Header hdr = null;
    private int timeout;
    private String hostname;
    private int port;
    private ConnectionState state;
    private int reconnectingAttempts;

    /**
     * Initializes the server connection.
     * @param hostname hostname/ip of the server
     * @param port port of the server
     * @param timeout time interval to ask for new events
     */
    public ServerConnection(String hostname, int port, int timeout)  {
        this.timeout = timeout;
        this.hostname = hostname;
        this.port = port;
        this.state = ConnectionState.CONNECTING;
        this.reconnectingAttempts = 1;
    }

    /**
     * Handles the logic for connecting to the server
     */
    public void connect()  {
        System.out.println("Connecting to " + hostname + ":" + port);

        while (!client.isConnected() && this.reconnectingAttempts <= 5){
            try {
                state = ConnectionState.CONNECTING;
                client.connect(hostname,port);
                client.setAutoReconnect(true); //this does nothing
                System.out.println("trying to connect to " + hostname + ":" + port );
            } catch (IOException e) {
                state = ConnectionState.TIMEOUT;
                System.out.println(hostname + ":" + port + " not reachable, trying to reconnect. Attempt: " + this.reconnectingAttempts);
                this.reconnectingAttempts++;
                try {
                    Thread.sleep(timeout);
                    //Display time in seconds
                    System.out.println("Time: "+ TimeUnit.MILLISECONDS.toSeconds(System.currentTimeMillis()));
                } catch (InterruptedException e1) {
                    e1.printStackTrace();
                }
            }
        }
        if(isConnected()) {
            state = ConnectionState.CONNECTED;
        }
        else {
            state = ConnectionState.CLOSED;
        }


        while (hdr == null) {
            if (client.isConnected()){
                try {
                    hdr = client.getHeader();
                } catch (IOException e) {
                    System.out.println("No header found at the server.");
                    //e.printStackTrace();
                }
            }

            //!!!For testing use only!!!
            if (hdr==null && client.isConnected()){
                System.out.println("Setting Header. ONLY FOR TESTING!!! SHOULD BE REMOVED IN THE FUTURE");
                setHeader();
            }
        }
        
    }

    /**
     * Gives access to the client which is connected to the server.
     * @return the client
     */
    public BufferClient getClient() {
        return this.client;
    }

    /**
     * Getter for the timeout
     * @return timout
     */
    public int getTimeout() {
        return this.timeout;
    }

    /**
     * Getter for the header
     * @return header
     */
    public Header getHeader(){
        return this.hdr;
    }

    /**
     * Safely disconnects the client from the server
     */
    public void disconnect()  {
        if (client.isConnected()){
            try {
                client.disconnect();
                state = ConnectionState.CLOSED;
            } catch (IOException e) {
                e.printStackTrace();
            }
        } else {
            System.out.println("The client isn't connected.");
        }
    }

    /**
     * Checks whether the client is connected to the server
     * @return
     */
    public boolean isConnected(){
        return client.isConnected();
    }

    public ConnectionState getState() {
        return this.state;
    }

    /**
     * Sets the header to a specific value.
     * For developing purpose only as this removes the dependency of a signal proxy running.
     */
    private void setHeader() {
        int channels = 1;
        int fsample = 1;
        int datatype = 1;
        hdr = new Header(channels, fsample,datatype);
        try {
            client.putHeader(hdr);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
