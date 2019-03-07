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

import java.io.IOException;

public class ExampleUsage {
    static String host = "localhost";
    static int port = 1972;
    static int timeout = 100;

    /**
     * Example Script to show the functionality of the server wrapper
     * You have a subscriber which listens to events and a publisher which can send events.
     * @param args
     * @throws IOException
     */
    public static void main(String[] args) {
        //Initialize the subscriber with a host and a port to connect to, the timeout says every how many seconds the client should update
        Subscriber sub = new Subscriber(host,port,timeout);
        Thread t = new Thread(sub);
        t.start();
        //Initialize the publisher with a host and a port to connect to, the timeout says every how many seconds the client should update

        //The subscriber needs to know which events to listen to, here are two example events
        sub.addListener("Key","W");
        sub.addListener("Key", "S");

        //Now that the subscriber listens to the events, the publisher can send them
        sub.publish("Key", "S");
        sub.publish("Key", "W");

        //because the server works in small steps we need to wait, to be sure everything appears on the screen
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        //should not appear twice, because the new subscriber has no listeners
        sub.publish("Key", "S");


        sub.addListener("Key", "W");
        //should appear twice, because the right listener was added
        sub.publish("Key", "W");

        //waiting for the results again
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }


        //adds a keyboard listener, which accepts integer arrays and converts them
        //the interpretation of the events can be changed at the subscriber
        sub.addKeyListener("Keyboard");
        int[] intarray = {1,2,3,4};
        sub.publish("Keyboard", intarray);

        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        // another way of adding a listeners through a anonymous function
        sub.addListenerWrapper("Keystroke", (value) -> {int[] array = sub.toIntArray(value);
            if (array[0] == 1) {
                System.out.println("Left");
            }
            return "";});
        int [] array = new int[] {1,0,0,0};
        sub.publish("Keystroke", array);
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        //in order to leave no threads running, please disconnect the subscriber and publisher after use
        sub.disconnect();
    }
}
