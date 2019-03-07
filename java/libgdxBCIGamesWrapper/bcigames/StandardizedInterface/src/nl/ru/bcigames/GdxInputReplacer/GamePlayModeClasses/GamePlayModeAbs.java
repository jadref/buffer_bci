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

import com.badlogic.gdx.Input;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Observer;

/**
 *  @author Samarpan Rai (greenspray)
 * The type Key command mode.
 */
public abstract class GamePlayModeAbs implements Observer {

    /**
     * The Current gdx command.
     */
    int currentGdxCommand = Input.Keys.UNKNOWN;

    /**
     *  Name of the command mode
     */
    private String commandModeName = "";

    /**
     * The Key command buffer.
     */
    KeyCommandsBuffer keyCommandBuffer;
    /**
     * The Key command with the highest Counts
     */
    CommandCounter highestKeyCommand;

    /**
     * Get current Gdx command from the Buffer BCi
     *
     * @return One of the keys corresponding to Gdx.Input.Keys
     */
    abstract public int getGdxCommand();

    /**
     * Reset the system to be ready to intercept new keys from
     * the Buffer BCi system
     */
    abstract public void reset();


    /** Set command mdoe name
     * @param commandModeName  name
     */
    public void setCommandModeName(String commandModeName) {
        this.commandModeName = commandModeName;
    }

    /**
     * @return Get command name
     */
    public String getCommandModeName(){
        return this.commandModeName;
    }



    /**
     * Gets highest key command with the highest counts.
     *
     * @return The Key command with the highest Counts
     */
    CommandCounter getHighestKeyCommand() {
        ArrayList<CommandCounter> keyCommands = keyCommandBuffer.getKeyCommands();
        return Collections.max(keyCommands, (commandCounter, t1) -> commandCounter.getCount().compareTo(t1.getCount()));
    }

}