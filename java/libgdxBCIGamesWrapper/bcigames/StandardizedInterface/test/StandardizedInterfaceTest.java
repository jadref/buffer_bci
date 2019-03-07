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
import nl.ru.bcigames.ServerWrapper.Subscriber;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class StandardizedInterfaceTest {
    /**
     * NOTE: Buffer Server has to be started on localhost to execute this test!
     */

    Subscriber pub;

    @BeforeEach
    void setUp() {
        pub = new Subscriber("localhost",1972,100);
        StandardizedInterface si = StandardizedInterface.getInstance();
        StandardizedInterface.BufferClient.connect();
    }

    @AfterEach
    void tearDown() {
        pub.disconnect();
        StandardizedInterface.BufferClient.disconnect();
    }

    @Test
    void getInstance() {
        StandardizedInterface si = StandardizedInterface.getInstance();
        assertNotNull(si);
    }

    @Test
    void isConnected() {
        assertTrue(StandardizedInterface.BufferClient.isConnected());
    }

    @Test
    void cancel() {
        StandardizedInterface.cancel();
        assertFalse(StandardizedInterface.BufferClient.isConnected());
    }

    @Test
    void KeyCommands() {
        //assertFalse(StandardizedInterface.KeyCommands.isDown(), "Down should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isUp(), "Up should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isRight(), "Right should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isLeft(), "Left should be false");

        int[] keyCommand = new int[4];
        keyCommand[1] = 1;
        pub.publish("Keystroke", keyCommand);
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        //assertTrue(StandardizedInterface.KeyCommands.isLeft(), "Left should be true");
        //assertFalse(StandardizedInterface.KeyCommands.isDown(), "Down should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isUp(), "Up should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isRight(), "Right should be false");

        pub.publish("Keystroke", keyCommand);
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        //assertTrue(StandardizedInterface.KeyCommands.isLeft(), "Left should be true");
        //assertFalse(StandardizedInterface.KeyCommands.isDown(), "Down should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isUp(), "Up should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isRight(), "Right should be false");

        keyCommand = new int[4];
        keyCommand[0] = 1;
        pub.publish("Keystroke", keyCommand);
        pub.publish("Keystroke", keyCommand);
        pub.publish("Keystroke", keyCommand);
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        //assertFalse(StandardizedInterface.KeyCommands.isLeft(), "Left should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isDown(), "Down should be false");
        //assertTrue(StandardizedInterface.KeyCommands.isUp(), "Up should be true");
        //assertFalse(StandardizedInterface.KeyCommands.isRight(), "Right should be false");

        //StandardizedInterface.KeyCommands.reset();

        //assertFalse(StandardizedInterface.KeyCommands.isDown(), "Down should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isUp(), "Up should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isRight(), "Right should be false");
        //assertFalse(StandardizedInterface.KeyCommands.isLeft(), "Left should be false");
    }
}