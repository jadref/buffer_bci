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
package nl.ru.bcigames.GdxInputReplacer.GamePlayModeClasses;

import java.util.ArrayList;
import java.util.Observable;

/**
 * @author Samarpan Rai (greenspray)
 *
 * This object is responsible for,
 *  1) Creating a subscriber event that listens for 'Keystroke' coming from the BufferClient
 *  2) Provide a way to set 1:1 Keystroke code between Gdx system and BufferClient
 *  3) Increment/decr
 */
public class KeyCommandsBuffer extends Observable {
    private final ArrayList<CommandCounter> keyCommands;

    private static KeyCommandsBuffer inst = null;
    /**
     * Instantiates a new Key commands buffer.
     */
    private KeyCommandsBuffer() {
        keyCommands = new ArrayList<>();

    }

    public static KeyCommandsBuffer getInstance() {
        if(inst == null)
            inst = new KeyCommandsBuffer();
        return inst;
    }


    public void update(int serverKeycode){
        for (CommandCounter commandCounter : keyCommands) {
            if (commandCounter.getServerKey() == serverKeycode) {
                commandCounter.incrCount();
                setChanged();
                notifyObservers();
            }
        }

    }

    /**
     * Add key command. The Gdx key must be one of the Keys from  {@link com.badlogic.gdx.Input.Keys}. Server key must be
     * an integer.
     * @param serverKey the server key
     * @param gdxKey    the gdx key
     */
    public void addKeyCommand(int serverKey, int gdxKey){
        keyCommands.add(new CommandCounter(serverKey,gdxKey));
    }

    /**
     * Gets all the key commands.
     *
     * @return the key commands
     */
    public ArrayList<CommandCounter> getKeyCommands() {
        return keyCommands;
    }


    /**
     * Reset key command counts to zero
     */
    public void resetKeyCommandCounts(){
        for(CommandCounter commandCounter : keyCommands){
            commandCounter.setCount(0);
        }
    }

    /**
     * For all Key Command  with existing counter > 1, decrease count by 1.
     */
    public void decrementBy1(){
        for(CommandCounter commandCounter : keyCommands){
            if(commandCounter.getCount() > 1)
                commandCounter.setCount(commandCounter.getCount()-1);
        }
    }

    public boolean decreaseAble(){
        for(CommandCounter commandCounter : keyCommands){
            if(commandCounter.getCount() > 1)
                return true;
        }
        return false;
    }




}
